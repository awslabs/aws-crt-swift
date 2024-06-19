// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import SwiftUI
import AwsCommonRuntimeKit

let TEST_HOST = "<endpoint>"
let TEST_PORT: UInt32 = 1883

@available(iOS 14.0, *)
struct ContentView: View {
    @StateObject var testContext = mqttTestContext
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

/// start client and check for connection success
func connectClient(client: Mqtt5Client, testContext: MqttTestContext) throws {
    try client.start()
    if testContext.semaphoreConnectionSuccess.wait(timeout: .now() + 5) == .timedOut {
        print("Connection Success Timed out after 5 seconds")
    }
}

/// stop client and check for discconnection and stopped lifecycle events
func disconnectClientCleanup(client: Mqtt5Client, testContext: MqttTestContext, disconnectPacket: DisconnectPacket? = nil) throws {
    try client.stop(disconnectPacket: disconnectPacket)

    if testContext.semaphoreDisconnection.wait(timeout: .now() + 5) == .timedOut {
        print("Disconnection timed out after 5 seconds")
    }

    if testContext.semaphoreStopped.wait(timeout: .now() + 5) == .timedOut {
        print("Stop timed out after 5 seconds")
    }
}

/// stop client and check for stopped lifecycle event
func stopClient(client: Mqtt5Client, testContext: MqttTestContext) throws {
    try client.stop()
    if testContext.semaphoreStopped.wait(timeout: .now() + 5) == .timedOut {
        print("Stop timed out after 5 seconds")
    }
}

func createClientId() -> String {
    return "aws-crt-swift-iOS-test-" + UUID().uuidString
}

var mqttTestContext = MqttTestContext(publishTarget: 10)

struct Message: Identifiable {
    let id: Int
    let text: String
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
    public let semaphorePublishTargetReached: DispatchSemaphore
    public let semaphoreConnectionSuccess: DispatchSemaphore
    public let semaphoreConnectionFailure: DispatchSemaphore
    public let semaphoreDisconnection: DispatchSemaphore
    public let semaphoreStopped: DispatchSemaphore

    public var negotiatedSettings: NegotiatedSettings?
    public var connackPacket: ConnackPacket?
    public var publishPacket: PublishPacket?
    public var lifecycleConnectionFailureData: LifecycleConnectionFailureData?
    public var lifecycleDisconnectionData: LifecycleDisconnectData?
    public var publishCount = 0
    public var publishTarget = 1

    func printView(_ message: String) {
        let newMessage = Message(id: messages.count, text: message)
        self.messages.append(newMessage)
        print(message)
    }

    init(contextName: String = "Client",
         publishTarget: Int = 1,
         onPublishReceived: OnPublishReceived? = nil,
         onLifecycleEventStopped: OnLifecycleEventStopped? = nil,
         onLifecycleEventAttemptingConnect: OnLifecycleEventAttemptingConnect? = nil,
         onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess? = nil,
         onLifecycleEventConnectionFailure: OnLifecycleEventConnectionFailure? = nil,
         onLifecycleEventDisconnection: OnLifecycleEventDisconnection? = nil) {

        self.contextName = contextName

        self.publishTarget = publishTarget
        self.publishCount = 0

        self.semaphorePublishReceived = DispatchSemaphore(value: 0)
        self.semaphorePublishTargetReached = DispatchSemaphore(value: 0)
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
            if let payloadString = publishData.publishPacket.payloadAsString() {
                self.printView(contextName +
                " Mqtt5ClientTests: onPublishReceived." +
                "Topic:\'\(publishData.publishPacket.topic)\' QoS:\(publishData.publishPacket.qos) payload:\'\(payloadString)\'")
            } else {
                self.printView(contextName +
                " Mqtt5ClientTests: onPublishReceived." +
                "Topic:\'\(publishData.publishPacket.topic)\' QoS:\(publishData.publishPacket.qos)")
            }
            self.publishPacket = publishData.publishPacket
            self.semaphorePublishReceived.signal()
            self.publishCount += 1
            if self.publishCount == self.publishTarget {
                self.semaphorePublishTargetReached.signal()
            }
        }

        self.onLifecycleEventStopped = onLifecycleEventStopped ?? { _ in
            self.printView(contextName + " Mqtt5ClientTests: onLifecycleEventStopped")
            self.semaphoreStopped.signal()
        }
        self.onLifecycleEventAttemptingConnect = onLifecycleEventAttemptingConnect ?? { _ in
            self.printView(contextName + " Mqtt5ClientTests: onLifecycleEventAttemptingConnect")
        }
        self.onLifecycleEventConnectionSuccess = onLifecycleEventConnectionSuccess ?? { successData in
            self.printView(contextName + " Mqtt5ClientTests: onLifecycleEventConnectionSuccess")
            self.negotiatedSettings = successData.negotiatedSettings
            self.connackPacket = successData.connackPacket
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

func createClient(clientOptions: MqttClientOptions?, testContext: MqttTestContext) throws -> Mqtt5Client {

    let clientOptionsWithCallbacks: MqttClientOptions

    if let clientOptions {
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
    } else {
        let elg = try EventLoopGroup()
        let resolver = try HostResolver.makeDefault(eventLoopGroup: elg)
        let clientBootstrap = try ClientBootstrap(
            eventLoopGroup: elg,
            hostResolver: resolver)
        let socketOptions = SocketOptions()

        clientOptionsWithCallbacks = MqttClientOptions(
            hostName: "172.20.10.8",
            port: 1883,
            bootstrap: clientBootstrap,
            socketOptions: socketOptions,
            onPublishReceivedFn: testContext.onPublishReceived,
            onLifecycleEventStoppedFn: testContext.onLifecycleEventStopped,
            onLifecycleEventAttemptingConnectFn: testContext.onLifecycleEventAttemptingConnect,
            onLifecycleEventConnectionSuccessFn: testContext.onLifecycleEventConnectionSuccess,
            onLifecycleEventConnectionFailureFn: testContext.onLifecycleEventConnectionFailure,
            onLifecycleEventDisconnectionFn: testContext.onLifecycleEventDisconnection)
    }

    let mqtt5Client = try Mqtt5Client(clientOptions: clientOptionsWithCallbacks)
    return mqtt5Client
}

func library_init() {
    Logger.initialize(pipe: stdout, level: .debug)
    CommonRuntimeKit.initialize()
}

var client: Mqtt5Client?

func setupClientAndStart() {
    let backgroundQueue = DispatchQueue(label: "background_queue",
                                        qos: .background)

    backgroundQueue.async {

        let inputHost = TEST_HOST
        let inputPort: UInt32 = TEST_PORT

        let ConnectPacket = MqttConnectOptions(keepAliveInterval: 60, clientId: createClientId())

        let clientOptions = MqttClientOptions(
            hostName: inputHost,
            port: inputPort,
            connectOptions: ConnectPacket, connackTimeout: TimeInterval(10))

        do {
            client = try createClient(clientOptions: clientOptions, testContext: mqttTestContext)
            try connectClient(client: client!, testContext: mqttTestContext)
        } catch {
            mqttTestContext.printView("Failed to setup client.")
        }

    }
}
