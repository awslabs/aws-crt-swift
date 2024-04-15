//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
import Foundation
import AwsCMqtt
@testable import AwsCommonRuntimeKit

func onPublishReceivedCallbackMinimal(_ : PublishReceivedData){
    print("Mqtt5ClientTests: onPublishReceivedCallbackMinimal")
}

func onLifecycleEventStoppedMinimal(_ : LifecycleStoppedData){
    print("Mqtt5ClientTests: onLifecycleEventStoppedMinimal")
}

func onLifecycleEventAttemptingConnectMinimal(_ : LifecycleAttemptingConnectData){
    print("Mqtt5ClientTests: onLifecycleEventAttemptingConnectMinimal")
}

func onLifecycleEventConnectionSuccessMinimal(_ : LifecycleConnectionSuccessData){
    print("Mqtt5ClientTests: onLifecycleEventConnectionSuccessMinimal")
}

func onLifecycleEventConnectionFailureMinimal(_ : LifecycleConnectionFailureData){
    print("Mqtt5ClientTests: onLifecycleEventConnectionFailureMinimal")
}

func onLifecycleEventDisconnectionMinimal(_ : LifecycleDisconnectData){
    print("Mqtt5ClientTests: onLifecycleEventDisconnectionMinimal")
}


class Mqtt5ClientTests: XCBaseTestCase {
    /*===============================================================
                     CREATION TEST CASES
    =================================================================*/
    /*
     * [New-UC1] Happy path. Minimal creation and cleanup
     */
    func testMqtt5ClientNewMinimal() throws {
        let elg = try EventLoopGroup()
        let resolver = try HostResolver(eventLoopGroup: elg,
                maxHosts: 8,
                maxTTL: 30)

        let clientBootstrap = try ClientBootstrap(eventLoopGroup: elg,
                hostResolver: resolver)
        XCTAssertNotNil(clientBootstrap)
        let socketOptions = SocketOptions()
        XCTAssertNotNil(socketOptions)
        let clientOptions = MqttClientOptions(hostName: "localhost", port: 1883, bootstrap: clientBootstrap,
                                   socketOptions: socketOptions);
        XCTAssertNotNil(clientOptions)
        let mqtt5client = try Mqtt5Client(clientOptions: clientOptions);
        XCTAssertNotNil(mqtt5client)

    }

    /*
     * [New-UC2] Maximum creation and cleanup
     */
    func testMqtt5ClientNewFull() throws {
        let elg = try EventLoopGroup()
        let resolver = try HostResolver(eventLoopGroup: elg,
                maxHosts: 8,
                maxTTL: 30)

        let clientBootstrap = try ClientBootstrap(eventLoopGroup: elg,
                hostResolver: resolver)
        XCTAssertNotNil(clientBootstrap)
        let socketOptions = SocketOptions()
        XCTAssertNotNil(socketOptions)
        let tlsOptions = TLSContextOptions()
        let tlsContext = try TLSContext(options: tlsOptions, mode: .client)
        let will = PublishPacket(qos: QoS.atLeastOnce, topic: "test/Mqtt5_Binding_SWIFT/testMqtt5ClientNewFull",
                                 payload: "will test".data(using: .utf8))

        let uuid = UUID().uuidString
        let connectOptions = MqttConnectOptions(
                            keepAliveInterval: 30,
                            clientId: "testMqtt5ClientNewFull_" + uuid,
                            sessionExpiryInterval: 1000,
                            requestResponseInformation: true,
                            requestProblemInformation: true,
                            receiveMaximum: 1000,
                            maximumPacketSize: 1000,
                            willDelayInterval: 1000,
                            will: will,
                            userProperties:   [UserProperty(name: "name1",value: "value1"),
                                               UserProperty(name: "name2",value: "value2"),
                                               UserProperty(name: "name3",value: "value3")])


        let clientOptions = MqttClientOptions( hostName: "localhost",
                                            port: 1883,
                                            bootstrap: clientBootstrap,
                                            socketOptions: socketOptions,
                                            tlsCtx: tlsContext,
                                            connectOptions: connectOptions,
                                            sessionBehavior: ClientSessionBehaviorType.clean,
                                            extendedValidationAndFlowControlOptions: ExtendedValidationAndFlowControlOptions.awsIotCoreDefaults,
                                            offlineQueueBehavior: ClientOperationQueueBehaviorType.failAllOnDisconnect,
                                            retryJitterMode: ExponentialBackoffJitterMode.full,
                                            minReconnectDelay: 1000,
                                            maxReconnectDelay: 1000,
                                            minConnectedTimeToResetReconnectDelay: 1000,
                                            pingTimeout: 10,
                                            connackTimeout: 10,
                                            ackTimeout: 60,
                                            topicAliasingOptions: TopicAliasingOptions(),
                                            onPublishReceivedFn: onPublishReceivedCallbackMinimal,
                                            onLifecycleEventStoppedFn: onLifecycleEventStoppedMinimal,
                                            onLifecycleEventAttemptingConnectFn: onLifecycleEventAttemptingConnectMinimal,
                                            onLifecycleEventConnectionFailureFn: onLifecycleEventConnectionFailureMinimal,
                                            onLifecycleEventDisconnectionFn: onLifecycleEventDisconnectionMinimal)
        XCTAssertNotNil(clientOptions)
        let mqtt5client = try Mqtt5Client(clientOptions: clientOptions);
        XCTAssertNotNil(mqtt5client)
    }

    func createClientId() -> String {
        return "aws-crt-swift-unit-test-" + UUID().uuidString
    }

    /*===============================================================
                     DIRECT CONNECT TEST CASES
    =================================================================*/

    class MqttTestContext {
        public var onPublishReceived: OnPublishReceived?
        public var onLifecycleEventStopped: OnLifecycleEventStopped?
        public var onLifecycleEventAttemptingConnect: OnLifecycleEventAttemptingConnect?
        public var onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess?
        public var onLifecycleEventConnectionFailure: OnLifecycleEventConnectionFailure?
        public var onLifecycleEventDisconnection: OnLifecycleEventDisconnection?

        public let semaphorePublishReceived:DispatchSemaphore
        public let semaphoreConnectionSuccess: DispatchSemaphore
        public let semaphoreConnectionFailure: DispatchSemaphore
        public let semaphoreDisconnection: DispatchSemaphore
        public let semaphoreStopped: DispatchSemaphore

        init(onPublishReceived: OnPublishReceived? = nil,
             onLifecycleEventStopped: OnLifecycleEventStopped? = nil,
             onLifecycleEventAttemptingConnect: OnLifecycleEventAttemptingConnect? = nil,
             onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess? = nil,
             onLifecycleEventConnectionFailure: OnLifecycleEventConnectionFailure? = nil,
             onLifecycleEventDisconnection: OnLifecycleEventDisconnection? = nil) {

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
                print("Mqtt5ClientTests: onPublishReceived. Publish Recieved on topic \'\(publishData.publishPacket.topic)\', with QoS \(publishData.publishPacket.qos): \'\(publishData.publishPacket.payloadAsString())\'")
                self.semaphorePublishReceived.signal()
            }
            self.onLifecycleEventStopped = onLifecycleEventStopped ?? { _ in
                print("Mqtt5ClientTests: onLifecycleEventStopped")
                self.semaphoreStopped.signal()
            }
            self.onLifecycleEventAttemptingConnect = onLifecycleEventAttemptingConnect ?? { _ in
                print("Mqtt5ClientTests: onLifecycleEventAttemptingConnect")
            }
            self.onLifecycleEventConnectionSuccess = onLifecycleEventConnectionSuccess ?? { _ in
                print("Mqtt5ClientTests: onLifecycleEventConnectionSuccess")
                self.semaphoreConnectionSuccess.signal()
            }
            self.onLifecycleEventConnectionFailure = onLifecycleEventConnectionFailure ?? { _ in
                print("Mqtt5ClientTests: onLifecycleEventConnectionFailure")
                self.semaphoreConnectionFailure.signal()
            }
            self.onLifecycleEventDisconnection = onLifecycleEventDisconnection ?? { _ in
                print("Mqtt5ClientTests: onLifecycleEventDisconnection")
                self.semaphoreDisconnection.signal()
            }
         }
    }

    func createClient(clientOptions: MqttClientOptions?, testContext: MqttTestContext) throws -> Mqtt5Client {

        let clientOptionsWithCallbacks: MqttClientOptions

        if let clientOptions = clientOptions {
            clientOptionsWithCallbacks = MqttClientOptions(
                hostName: clientOptions.hostName,
                port: clientOptions.port,
                bootstrap: clientOptions.bootstrap,
                socketOptions: clientOptions.socketOptions,
                tlsCtx: clientOptions.tlsCtx,
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
            let resolver = try HostResolver(eventLoopGroup: elg,
                maxHosts: 8,
                maxTTL: 30)
            let clientBootstrap = try ClientBootstrap(
                eventLoopGroup: elg,
                hostResolver: resolver)
            let socketOptions = SocketOptions()

            clientOptionsWithCallbacks = MqttClientOptions(
                hostName: "localhost",
                port: 443,
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
        XCTAssertNotNil(mqtt5Client)
        return mqtt5Client
    }

    /*
     * [ConnDC-UC1] Happy path
     */

    func testMqtt5DirectConnectMinimum() throws {
        let inputHost = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_DIRECT_MQTT_HOST")
        let inputPort = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_DIRECT_MQTT_PORT")

        let clientOptions = MqttClientOptions(
            hostName: inputHost,
            port: UInt32(inputPort)!)

        let testContext = MqttTestContext()
        let client = try createClient(clientOptions: clientOptions, testContext: testContext)
        try client.start()
        if testContext.semaphoreConnectionSuccess.wait(timeout: .now() + 5) == .timedOut {
            print("Connection Success Timed out after 5 seconds")
            XCTFail("Connection Timed Out")
        }

        try client.stop()
        if testContext.semaphoreDisconnection.wait(timeout: .now() + 5) == .timedOut {
            print("Disconnection timed out after 5 seconds")
            XCTFail("Disconnection timed out")
        }

        if testContext.semaphoreStopped.wait(timeout: .now() + 5) == .timedOut {
            print("Stop timed out after 5 seconds")
            XCTFail("Stop timed out")
        }
    }

    /*
     * [ConnDC-UC2] Direct Connection with Basic Authentication
     */

    func testMqtt5DirectConnectWithBasicAuth() throws {

        let inputUsername = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_BASIC_AUTH_USERNAME")
        let inputPassword = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_BASIC_AUTH_PASSWORD")
        let inputHost = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_DIRECT_MQTT_HOST")
        let inputPort = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_DIRECT_MQTT_PORT")

        let connectOptions = MqttConnectOptions(
            clientId: createClientId(),
            username: inputUsername,
            password: inputPassword
        )

        let clientOptions = MqttClientOptions(
            hostName: inputHost,
            port: UInt32(inputPort)!,
            connectOptions: connectOptions)

        let testContext = MqttTestContext()
        let client = try createClient(clientOptions: clientOptions, testContext: testContext)
        try client.start()
        if testContext.semaphoreConnectionSuccess.wait(timeout: .now() + 5) == .timedOut {
            print("Connection Success Timed out after 5 seconds")
            XCTFail("Connection Timed Out")
        }

        try client.stop()
        if testContext.semaphoreDisconnection.wait(timeout: .now() + 5) == .timedOut {
            print("Disconnection timed out after 5 seconds")
            XCTFail("Disconnection timed out")
        }

        if testContext.semaphoreStopped.wait(timeout: .now() + 5) == .timedOut {
            print("Stop timed out after 5 seconds")
            XCTFail("Stop timed out")
        }
    }

    /*
     * [ConnDC-UC3] Direct Connection with TLS
     */

    func testMqtt5DirectConnectWithTLS() throws {

        let inputHost = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_DIRECT_MQTT_TLS_HOST")
        let inputPort = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_DIRECT_MQTT_TLS_PORT")

        let tlsOptions = TLSContextOptions()
        tlsOptions.setVerifyPeer(false)
        let tlsContext = try TLSContext(options: tlsOptions, mode: .client)

        let clientOptions = MqttClientOptions(
            hostName: inputHost,
            port: UInt32(inputPort)!,
            tlsCtx: tlsContext)

        let testContext = MqttTestContext()
        let client = try createClient(clientOptions: clientOptions, testContext: testContext)
        try client.start()
        if testContext.semaphoreConnectionSuccess.wait(timeout: .now() + 5) == .timedOut {
            print("Connection Success Timed out after 5 seconds")
            XCTFail("Connection Timed Out")
        }

        try client.stop()
        if testContext.semaphoreDisconnection.wait(timeout: .now() + 5) == .timedOut {
            print("Disconnection timed out after 5 seconds")
            XCTFail("Disconnection timed out")
        }

        if testContext.semaphoreStopped.wait(timeout: .now() + 5) == .timedOut {
            print("Stop timed out after 5 seconds")
            XCTFail("Stop timed out")
        }
    }

    /*
     * [ConnDC-UC4] Direct Connection with mutual TLS
     */

    func testMqtt5DirectConnectWithMutualTLS() throws {

        let inputHost = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")
        let inputCert = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_CERT")
        let inputKey = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_KEY")

        let tlsOptions = try TLSContextOptions.makeMTLS(
            certificatePath: inputCert,
            privateKeyPath: inputKey
        )
        let tlsContext = try TLSContext(options: tlsOptions, mode: .client)

        let clientOptions = MqttClientOptions(
            hostName: inputHost,
            port: UInt32(8883),
            tlsCtx: tlsContext)

        let testContext = MqttTestContext()
        let client = try createClient(clientOptions: clientOptions, testContext: testContext)
        try client.start()
        if testContext.semaphoreConnectionSuccess.wait(timeout: .now() + 5) == .timedOut {
            print("Connection Success Timed out after 5 seconds")
            XCTFail("Connection Timed Out")
        }

        try client.stop()
        if testContext.semaphoreDisconnection.wait(timeout: .now() + 5) == .timedOut {
            print("Disconnection timed out after 5 seconds")
            XCTFail("Disconnection timed out")
        }

        if testContext.semaphoreStopped.wait(timeout: .now() + 5) == .timedOut {
            print("Stop timed out after 5 seconds")
            XCTFail("Stop timed out")
        }
    }

    /*
     * [ConnDC-UC5] Direct Connection with HttpProxy options and TLS
     */

    func testMqtt5DirectConnectWithHttpProxy() throws {

        let inputHost = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_DIRECT_MQTT_TLS_HOST")
        let inputPort = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_DIRECT_MQTT_TLS_PORT")
        let inputProxyHost = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_PROXY_HOST")
        let inputProxyPort = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_PROXY_PORT")

        let tlsOptions = TLSContextOptions()
        tlsOptions.setVerifyPeer(false)
        let tlsContext = try TLSContext(options: tlsOptions, mode: .client)

        let httpProxyOptions = HTTPProxyOptions(
            hostName: inputProxyHost,
            port: UInt32(inputProxyPort)!,
            connectionType: HTTPProxyConnectionType.tunnel)

        let clientOptions = MqttClientOptions(
            hostName: inputHost,
            port: UInt32(inputPort)!,
            tlsCtx: tlsContext,
            httpProxyOptions: httpProxyOptions)

        let testContext = MqttTestContext()
        let client = try createClient(clientOptions: clientOptions, testContext: testContext)
        try client.start()
        if testContext.semaphoreConnectionSuccess.wait(timeout: .now() + 5) == .timedOut {
            print("Connection Success Timed out after 5 seconds")
            XCTFail("Connection Timed Out")
        }

        try client.stop()
        if testContext.semaphoreDisconnection.wait(timeout: .now() + 5) == .timedOut {
            print("Disconnection timed out after 5 seconds")
            XCTFail("Disconnection timed out")
        }

        if testContext.semaphoreStopped.wait(timeout: .now() + 5) == .timedOut {
            print("Stop timed out after 5 seconds")
            XCTFail("Stop timed out")
        }
    }

    /*
     * [ConnDC-UC6] Direct Connection with all options set
     */

    func testMqtt5DirectConnectMaximum() throws {

        let inputHost = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_DIRECT_MQTT_HOST")
        let inputPort = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_DIRECT_MQTT_PORT")

        let userProperties = [UserProperty(name: "name1", value: "value1"),
                              UserProperty(name: "name2", value: "value2")]

        let willPacket = PublishPacket(
            qos: QoS.atLeastOnce,
            topic: "TEST_TOPIC",
            payload: "TEST_PAYLOAD".data(using: .utf8),
            retain: false,
            payloadFormatIndicator: PayloadFormatIndicator.utf8,
            messageExpiryInterval: TimeInterval(10),
            topicAlias: UInt16(1),
            responseTopic: "TEST_RESPONSE_TOPIC",
            correlationData: "TEST_CORRELATION_DATA".data(using: .utf8),
            contentType: "TEST_CONTENT_TYPE",
            userProperties: userProperties)

        let connectOptions = MqttConnectOptions(
            keepAliveInterval: TimeInterval(10),
            clientId: createClientId(),
            sessionExpiryInterval: TimeInterval(100),
            requestResponseInformation: true,
            requestProblemInformation: true,
            receiveMaximum: 1000,
            maximumPacketSize: 10000,
            willDelayInterval: TimeInterval(1000),
            will: willPacket,
            userProperties: userProperties)

        let clientOptions = MqttClientOptions(
            hostName: inputHost,
            port: UInt32(inputPort)!,
            connectOptions: connectOptions,
            sessionBehavior: ClientSessionBehaviorType.clean,
            extendedValidationAndFlowControlOptions: ExtendedValidationAndFlowControlOptions.awsIotCoreDefaults,
            offlineQueueBehavior: ClientOperationQueueBehaviorType.failAllOnDisconnect,
            retryJitterMode: ExponentialBackoffJitterMode.decorrelated,
            minReconnectDelay: TimeInterval(0.1),
            maxReconnectDelay: TimeInterval(50),
            minConnectedTimeToResetReconnectDelay: TimeInterval(1),
            pingTimeout: TimeInterval(1),
            connackTimeout: TimeInterval(1),
            ackTimeout: TimeInterval(100))

        let testContext = MqttTestContext()
        let client = try createClient(clientOptions: clientOptions, testContext: testContext)
        try client.start()
        if testContext.semaphoreConnectionSuccess.wait(timeout: .now() + 5) == .timedOut {
            print("Connection Success Timed out after 5 seconds")
            XCTFail("Connection Timed Out")
        }

        try client.stop()
        if testContext.semaphoreDisconnection.wait(timeout: .now() + 5) == .timedOut {
            print("Disconnection timed out after 5 seconds")
            XCTFail("Disconnection timed out")
        }

        if testContext.semaphoreStopped.wait(timeout: .now() + 5) == .timedOut {
            print("Stop timed out after 5 seconds")
            XCTFail("Stop timed out")
        }
    }

    /** Operation Tests [OP-UC] */

    // Sub Happy Path
    func testSubscription() async throws {
        let uuid = UUID()
        let testTopic = "testSubscription_" + uuid.uuidString
        let inputHost = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_DIRECT_MQTT_HOST")
        let inputPort = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_DIRECT_MQTT_PORT")

        let clientOptions = MqttClientOptions(
            hostName: inputHost,
            port: UInt32(inputPort)!)

        let testContext = MqttTestContext()
        let client = try createClient(clientOptions: clientOptions, testContext: testContext)
        try client.start()
        if testContext.semaphoreConnectionSuccess.wait(timeout: .now() + 5) == .timedOut {
            print("Connection Success Timed out after 5 seconds")
            XCTFail("Connection Timed Out")
        }

        let subscribe = SubscribePacket(topicFilter: testTopic, qos: QoS.atLeastOnce)
        async let _ = client.subscribe(subscribePacket: subscribe)
        async let _ =  client.publish(publishPacket: PublishPacket(qos: QoS.atLeastOnce,
                                                                           topic: testTopic,
                                                                           payload: "testSubscription".data(using: .utf8)))

        testContext.semaphorePublishReceived.wait()

        try client.stop()
        if testContext.semaphoreDisconnection.wait(timeout: .now() + 5) == .timedOut {
            print("Disconnection timed out after 5 seconds")
            XCTFail("Disconnection timed out")
        }

        if testContext.semaphoreStopped.wait(timeout: .now() + 5) == .timedOut {
            print("Stop timed out after 5 seconds")
            XCTFail("Stop timed out")
        }
    }
}
