// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import SwiftUI
import AwsCommonRuntimeKit

// The app setup a direct connection with default TLS options.
// Update the host and port before run the app.
let TEST_HOST = "<endpoint>"
let TEST_PORT: UInt32 = 1883
var mqttTestContext = MqttTestContext()
var client: Mqtt5Client?

struct ContentView: View {
    @ObservedObject var testContext = mqttTestContext
    var body: some View {
        VStack {
            Button("Setup Client and Start") {
                do {
                    library_init()
                    setupClientAndStart()
                }
            }
            NavigationView {
                List(testContext.messages) { message in
                    HStack {
                        Text(message.text)
                    }
                 }.navigationBarTitle(Text("Messages"))
            }
        }
        .padding()
    }

}

/// Message struct for information print
struct Message: Identifiable {
    let id: Int
    let text: String
}

/// start client and check for connection success
func connectClient(client: Mqtt5Client, testContext: MqttTestContext) throws {
    try client.start()
    if testContext.semaphoreConnectionSuccess.wait(timeout: .now() + 5) == .timedOut {
        print("Connection Success Timed out after 5 seconds")
    }
}

/// stop client and check for stopped lifecycle event
func stopClient(client: Mqtt5Client, testContext: MqttTestContext) throws {
    try client.stop()
    if testContext.semaphoreStopped.wait(timeout: .now() + 5) == .timedOut {
        print("Stop timed out after 5 seconds")
    }
}

/// generate a random client id
func createClientId() -> String {
    return "aws-crt-swift-iOS-test-" + UUID().uuidString
}

class MqttTestContext: ObservableObject {
    @Published var messages: [Message] = [Message(id: 0, text: "Click the \"Setup Client and Start\" to start the client.")]

    public var contextName: String

    public var onPublishReceived: OnPublishReceived?
    public var onLifecycleEventStopped: OnLifecycleEventStopped?
    public var onLifecycleEventAttemptingConnect: OnLifecycleEventAttemptingConnect?
    public var onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess?
    public var onLifecycleEventConnectionFailure: OnLifecycleEventConnectionFailure?
    public var onLifecycleEventDisconnection: OnLifecycleEventDisconnection?
    public var onWebSocketHandshake: OnWebSocketHandshakeIntercept?

    public let semaphorePublishReceived: DispatchSemaphore
    public let semaphoreConnectionSuccess: DispatchSemaphore
    public let semaphoreConnectionFailure: DispatchSemaphore
    public let semaphoreDisconnection: DispatchSemaphore
    public let semaphoreStopped: DispatchSemaphore

    public var lifecycleConnectionFailureData: LifecycleConnectionFailureData?
    public var lifecycleDisconnectionData: LifecycleDisconnectData?
    public var publishCount = 0

    /// Print the text and pending new message to message list
    func printView(_ txt: String) {
        let newMessage = Message(id: messages.count, text: txt)
        self.messages.append(newMessage)
        print(txt)
    }

    init(contextName: String = "Client",
         onPublishReceived: OnPublishReceived? = nil,
         onLifecycleEventStopped: OnLifecycleEventStopped? = nil,
         onLifecycleEventAttemptingConnect: OnLifecycleEventAttemptingConnect? = nil,
         onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess? = nil,
         onLifecycleEventConnectionFailure: OnLifecycleEventConnectionFailure? = nil,
         onLifecycleEventDisconnection: OnLifecycleEventDisconnection? = nil) {

        self.contextName = contextName

        self.publishCount = 0

        self.semaphorePublishReceived = DispatchSemaphore(value: 0)
        self.semaphoreConnectionSuccess = DispatchSemaphore(value: 0)
        self.semaphoreConnectionFailure = DispatchSemaphore(value: 0)
        self.semaphoreDisconnection = DispatchSemaphore(value: 0)
        self.semaphoreStopped = DispatchSemaphore(value: 0)

        self.onPublishReceived = onPublishReceived
        self.onLifecycleEventStopped = onLifecycleEventStopped
        self.onLifecycleEventAttemptingConnect = onLifecycleEventAttemptingConnect
        self.onLifecycleEventConnectionSuccess = onLifecycleEventConnectionSuccess
        self.onLifecycleEventConnectionFailure = onLifecycleEventConnectionFailure
        self.onLifecycleEventDisconnection = onLifecycleEventDisconnection

        self.onPublishReceived = onPublishReceived ?? { publishData in
            var message = contextName + " Mqtt5ClientTests: onPublishReceived." +
            "Topic:\'\(publishData.publishPacket.topic)\' QoS:\(publishData.publishPacket.qos)"
            if let payloadString = publishData.publishPacket.payloadAsString() {
                message += "payload:\'\(payloadString)\'"
            }
            // Pending received publish to message list
            self.printView(message)
            self.semaphorePublishReceived.signal()
            self.publishCount += 1
        }

        self.onLifecycleEventStopped = onLifecycleEventStopped ?? { _ in
            self.printView(contextName + " Mqtt5ClientTests: onLifecycleEventStopped")
            self.semaphoreStopped.signal()
        }
        self.onLifecycleEventAttemptingConnect = onLifecycleEventAttemptingConnect ?? { _ in
            self.printView(contextName + " Mqtt5ClientTests: onLifecycleEventAttemptingConnect")
        }
        self.onLifecycleEventConnectionSuccess = onLifecycleEventConnectionSuccess ?? { _ in
            self.printView(contextName + " Mqtt5ClientTests: onLifecycleEventConnectionSuccess")
            // Subscribe to test/topic on connection success
            Task {
                async let _ = try await client!.subscribe(subscribePacket: SubscribePacket(
                    subscription: Subscription(topicFilter: "test/topic", qos: QoS.atLeastOnce)))
            }
            self.semaphoreConnectionSuccess.signal()
        }
        self.onLifecycleEventConnectionFailure = onLifecycleEventConnectionFailure ?? { failureData in
            self.printView(contextName + " Mqtt5ClientTests: onLifecycleEventConnectionFailure")
            self.lifecycleConnectionFailureData = failureData
            self.semaphoreConnectionFailure.signal()
        }
        self.onLifecycleEventDisconnection = onLifecycleEventDisconnection ?? { disconnectionData in
            self.printView(contextName + " Mqtt5ClientTests: onLifecycleEventDisconnection")
            self.lifecycleDisconnectionData = disconnectionData
            self.semaphoreDisconnection.signal()
        }
    }
}

// Create client from client options and test context
func createClient(clientOptions: MqttClientOptions, testContext: MqttTestContext) throws -> Mqtt5Client {

    let clientOptionsWithCallbacks: MqttClientOptions

    clientOptionsWithCallbacks = MqttClientOptions(
        hostName: clientOptions.hostName,
        port: clientOptions.port,
        bootstrap: clientOptions.bootstrap,
        socketOptions: clientOptions.socketOptions,
        tlsCtx: clientOptions.tlsCtx,
        onWebsocketTransform: testContext.onWebSocketHandshake,
        httpProxyOptions: clientOptions.httpProxyOptions,
        connectOptions: clientOptions.connectOptions,
        sessionBehavior: clientOptions.sessionBehavior,
        extendedValidationAndFlowControlOptions: clientOptions.extendedValidationAndFlowControlOptions,
        offlineQueueBehavior: clientOptions.offlineQueueBehavior,
        retryJitterMode: clientOptions.retryJitterMode,
        minReconnectDelay: clientOptions.minReconnectDelay,
        maxReconnectDelay: clientOptions.maxReconnectDelay,
        minConnectedTimeToResetReconnectDelay: clientOptions.minConnectedTimeToResetReconnectDelay,
        pingTimeout: clientOptions.pingTimeout,
        connackTimeout: clientOptions.connackTimeout,
        ackTimeout: clientOptions.ackTimeout,
        topicAliasingOptions: clientOptions.topicAliasingOptions,
        onPublishReceivedFn: testContext.onPublishReceived,
        onLifecycleEventStoppedFn: testContext.onLifecycleEventStopped,
        onLifecycleEventAttemptingConnectFn: testContext.onLifecycleEventAttemptingConnect,
        onLifecycleEventConnectionSuccessFn: testContext.onLifecycleEventConnectionSuccess,
        onLifecycleEventConnectionFailureFn: testContext.onLifecycleEventConnectionFailure,
        onLifecycleEventDisconnectionFn: testContext.onLifecycleEventDisconnection)

    let mqtt5Client = try Mqtt5Client(clientOptions: clientOptionsWithCallbacks)
    return mqtt5Client
}

/// Init CRT library
func library_init() {
    try? Logger.initialize(target: .standardOutput, level: .debug)
    CommonRuntimeKit.initialize()
}

/// Setup the client and start the session.
func setupClientAndStart() {
    let backgroundQueue = DispatchQueue(label: "background_queue",
                                        qos: .background)

    backgroundQueue.async {

        let ConnectPacket = MqttConnectOptions(keepAliveInterval: 60, clientId: createClientId())

        let clientOptions = MqttClientOptions(
            hostName: TEST_HOST,
            port: TEST_PORT,
            connectOptions: ConnectPacket,
            connackTimeout: TimeInterval(10))

        do {
            client = try createClient(clientOptions: clientOptions, testContext: mqttTestContext)
            try connectClient(client: client!, testContext: mqttTestContext)
        } catch {
            mqttTestContext.printView("Failed to setup client.")
        }
    }
}
