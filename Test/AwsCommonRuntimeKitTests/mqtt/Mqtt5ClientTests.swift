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

    func createClientId() -> String {
        return "aws-crt-swift-unit-test-" + UUID().uuidString
    }

    class MqttTestContext {
        public var contextName: String

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

        public var negotiatedSettings: NegotiatedSettings?
        public var connackPacket: ConnackPacket?
        public var lifecycleConnectionFailureData: LifecycleConnectionFailureData?
        public var lifecycleDisconnectionData: LifecycleDisconnectData?

        init(contextName: String = "",
             onPublishReceived: OnPublishReceived? = nil,
             onLifecycleEventStopped: OnLifecycleEventStopped? = nil,
             onLifecycleEventAttemptingConnect: OnLifecycleEventAttemptingConnect? = nil,
             onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess? = nil,
             onLifecycleEventConnectionFailure: OnLifecycleEventConnectionFailure? = nil,
             onLifecycleEventDisconnection: OnLifecycleEventDisconnection? = nil) {

            self.contextName = contextName

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
                print(contextName + " Mqtt5ClientTests: onLifecycleEventStopped")
                self.semaphoreStopped.signal()
            }
            self.onLifecycleEventAttemptingConnect = onLifecycleEventAttemptingConnect ?? { _ in
                print(contextName + " Mqtt5ClientTests: onLifecycleEventAttemptingConnect")
            }
            self.onLifecycleEventConnectionSuccess = onLifecycleEventConnectionSuccess ?? { successData in
                print(contextName + " Mqtt5ClientTests: onLifecycleEventConnectionSuccess")
                self.negotiatedSettings = successData.negotiatedSettings
                self.connackPacket = successData.connackPacket
                self.semaphoreConnectionSuccess.signal()
            }
            self.onLifecycleEventConnectionFailure = onLifecycleEventConnectionFailure ?? { failureData in
                print(contextName + " Mqtt5ClientTests: onLifecycleEventConnectionFailure")
                self.lifecycleConnectionFailureData = failureData
                self.semaphoreConnectionFailure.signal()
            }
            self.onLifecycleEventDisconnection = onLifecycleEventDisconnection ?? { disconnectionData in
                print(contextName + " Mqtt5ClientTests: onLifecycleEventDisconnection")
                self.lifecycleDisconnectionData = disconnectionData
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

    /*===============================================================
                     DIRECT CONNECT TEST CASES
    =================================================================*/
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
        let inputHost = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_DIRECT_MQTT_BASIC_AUTH_HOST")
        let inputPort = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_DIRECT_MQTT_BASIC_AUTH_PORT")

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
#if os(macOS) || os(Linux)
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
#endif

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

    /*===============================================================
                     WEBSOCKET CONNECT TEST CASES
    =================================================================*/
    // TODO implement websocket tests after websockets are implemented

    /*===============================================================
                     NEGATIVE CONNECT TEST CASES
    =================================================================*/

    /*
     * [ConnNegativeID-UC1] Client connect with invalid host name
     */
    func testMqtt5DirectConnectWithInvalidHost() throws {

        let clientOptions = MqttClientOptions(
            hostName: "badhost",
            port: UInt32(1883))

        let testContext = MqttTestContext()

        let client = try createClient(clientOptions: clientOptions, testContext: testContext)
        try client.start()

        if testContext.semaphoreConnectionFailure.wait(timeout: .now() + 5) == .timedOut {
            print("Connection Failure Timed out after 5 seconds")
            XCTFail("Connection Timed Out")
        }

        if let failureData = testContext.lifecycleConnectionFailureData {
            XCTAssertEqual(failureData.crtError.code, Int32(AWS_IO_DNS_INVALID_NAME.rawValue))
        } else {
            XCTFail("lifecycleConnectionFailureData Missing")
        }

        try client.stop()

        if testContext.semaphoreStopped.wait(timeout: .now() + 5) == .timedOut {
            print("Stop timed out after 5 seconds")
            XCTFail("Stop timed out")
        }
    }

    /*
     * [ConnNegativeID-UC2] Client connect with invalid port for direct connection
     */
    func testMqtt5DirectConnectWithInvalidPort() throws {
        let inputHost = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_DIRECT_MQTT_HOST")

        let clientOptions = MqttClientOptions(
            hostName: inputHost,
            port: UInt32(444))

        let testContext = MqttTestContext()

        let client = try createClient(clientOptions: clientOptions, testContext: testContext)
        try client.start()

        if testContext.semaphoreConnectionFailure.wait(timeout: .now() + 5) == .timedOut {
            print("Connection Failure Timed out after 5 seconds")
            XCTFail("Connection Timed Out")
        }

        if let failureData = testContext.lifecycleConnectionFailureData {
            if failureData.crtError.code != Int32(AWS_IO_SOCKET_CONNECTION_REFUSED.rawValue) &&
               failureData.crtError.code != Int32(AWS_IO_SOCKET_TIMEOUT.rawValue) {
                XCTFail("Did not fail with expected error code")
            }
        } else {
            XCTFail("lifecycleConnectionFailureData Missing")
        }

        try client.stop()

        if testContext.semaphoreStopped.wait(timeout: .now() + 5) == .timedOut {
            print("Stop timed out after 5 seconds")
            XCTFail("Stop timed out")
        }
    }

    /*
     * [ConnNegativeID-UC3] Client connect with invalid port for websocket connection
     */
     // TODO implement this test after websocket is implemented

    /*
     * [ConnNegativeID-UC4] Client connect with socket timeout
     */
    func testMqtt5DirectConnectWithSocketTimeout() throws {
        let clientOptions = MqttClientOptions(
            hostName: "www.example.com",
            port: UInt32(81))

        let testContext = MqttTestContext()

        let client = try createClient(clientOptions: clientOptions, testContext: testContext)
        try client.start()

        if testContext.semaphoreConnectionFailure.wait(timeout: .now() + 5) == .timedOut {
            print("Connection Failure Timed out after 5 seconds")
            XCTFail("Connection Timed Out")
        }

        if let failureData = testContext.lifecycleConnectionFailureData {
            XCTAssertEqual(failureData.crtError.code, Int32(AWS_IO_SOCKET_TIMEOUT.rawValue))
        } else {
            XCTFail("lifecycleConnectionFailureData Missing")
        }

        try client.stop()

        if testContext.semaphoreStopped.wait(timeout: .now() + 5) == .timedOut {
            print("Stop timed out after 5 seconds")
            XCTFail("Stop timed out")
        }
    }

    /*
     * [ConnNegativeID-UC5] Client connect with incorrect basic authentication credentials
     */
    func testMqtt5DirectConnectWithIncorrectBasicAuthenticationCredentials() throws {
        let inputHost = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_DIRECT_MQTT_BASIC_AUTH_HOST")
        let inputPort = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_DIRECT_MQTT_BASIC_AUTH_PORT")

        let clientOptions = MqttClientOptions(
            hostName: inputHost,
            port: UInt32(inputPort)!)

        let testContext = MqttTestContext()

        let client = try createClient(clientOptions: clientOptions, testContext: testContext)
        try client.start()

        if testContext.semaphoreConnectionFailure.wait(timeout: .now() + 5) == .timedOut {
            print("Connection Failure Timed out after 5 seconds")
            XCTFail("Connection Timed Out")
        }

        if let failureData = testContext.lifecycleConnectionFailureData {
            XCTAssertEqual(failureData.crtError.code, Int32(AWS_ERROR_MQTT5_CONNACK_CONNECTION_REFUSED.rawValue))
        } else {
            XCTFail("lifecycleConnectionFailureData Missing")
        }

        try client.stop()

        if testContext.semaphoreStopped.wait(timeout: .now() + 5) == .timedOut {
            print("Stop timed out after 5 seconds")
            XCTFail("Stop timed out")
        }
    }

    /*
     * [ConnNegativeID-UC6] Client Websocket Handshake Failure test
     */
     // TODO Implement this test after implementation of Websockets

    /*
    * [ConnNegativeID-UC7] Double Client ID Failure test
    */
    #if os(macOS) || os(Linux)
    func testMqtt5MTLSConnectDoubleClientIdFailure() throws {

        let inputHost = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")
        let inputCert = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_CERT")
        let inputKey = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_KEY")

        let tlsOptions = try TLSContextOptions.makeMTLS(
            certificatePath: inputCert,
            privateKeyPath: inputKey
        )
        let tlsContext = try TLSContext(options: tlsOptions, mode: .client)

        let clientId = createClientId()

        let connectOptions = MqttConnectOptions(clientId: clientId)

        let clientOptions = MqttClientOptions(
            hostName: inputHost,
            port: UInt32(8883),
            tlsCtx: tlsContext,
            connectOptions: connectOptions,
            minReconnectDelay: TimeInterval(5))

        let testContext = MqttTestContext(contextName: "client1")
        let client = try createClient(clientOptions: clientOptions, testContext: testContext)
        try client.start()
        if testContext.semaphoreConnectionSuccess.wait(timeout: .now() + 5) == .timedOut {
            print("Connection Success Timed out after 5 seconds")
            XCTFail("Connection Timed Out")
        }

        // Create a second client with the same client id
        let testContext2 = MqttTestContext(contextName: "client2")
        let client2 = try createClient(clientOptions: clientOptions, testContext: testContext2)

        // Connect with second client
        try client2.start()

        // Check for client2 successful connect
        if testContext2.semaphoreConnectionSuccess.wait(timeout: .now() + 5) == .timedOut {
            print("Connection Success Timed out on client2 after 5 seconds")
            XCTFail("Connection Timed Out")
        }

        if testContext.semaphoreDisconnection.wait(timeout: .now() + 5) == .timedOut {
            print("Disconnection due to duplicate client id timed out on client1")
            XCTFail("Disconnection Timed Out")
        }

        if let disconnectionData = testContext.lifecycleDisconnectionData {
            print(disconnectionData.crtError)
            if let disconnectionPacket = disconnectionData.disconnectPacket {
                XCTAssertEqual(disconnectionPacket.reasonCode, DisconnectReasonCode.sessionTakenOver)
            } else {
                XCTFail("DisconnectPacket missing")
            }
        } else {
            XCTFail("lifecycleDisconnectionData Missing")
        }

        try client.stop()

        if testContext.semaphoreStopped.wait(timeout: .now() + 5) == .timedOut {
            print("Stop timed out after 5 seconds")
            XCTFail("Stop timed out")
        }

        try client2.stop()
        if testContext2.semaphoreDisconnection.wait(timeout: .now() + 5) == .timedOut {
            print("Disconnection timed out after 5 seconds")
            XCTFail("Disconnection timed out")
        }

        if testContext2.semaphoreStopped.wait(timeout: .now() + 5) == .timedOut {
            print("Stop timed out after 5 seconds")
            XCTFail("Stop timed out")
        }
    }
#endif

    /*===============================================================
                         NEGOTIATED SETTINGS TESTS
    =================================================================*/
    /*
    * [Negotiated-UC1] Happy path, minimal success test
    */
    func testMqtt5NegotiatedSettingsMinimalSettings() throws {
        let inputHost = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_DIRECT_MQTT_HOST")
        let inputPort = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_DIRECT_MQTT_PORT")

        let sessionExpirtyInterval = TimeInterval(600000)

        let mqttConnectOptions = MqttConnectOptions(sessionExpiryInterval: sessionExpirtyInterval)

        let clientOptions = MqttClientOptions(
            hostName: inputHost,
            port: UInt32(inputPort)!,
            connectOptions: mqttConnectOptions)

        let testContext = MqttTestContext()
        let client = try createClient(clientOptions: clientOptions, testContext: testContext)
        try client.start()
        if testContext.semaphoreConnectionSuccess.wait(timeout: .now() + 5) == .timedOut {
            print("Connection Success Timed out after 5 seconds")
            XCTFail("Connection Timed Out")
        }

        if let negotiatedSettings = testContext.negotiatedSettings {
            XCTAssertEqual(negotiatedSettings.sessionExpiryInterval, sessionExpirtyInterval)
        } else {
            XCTFail("Missing negotiated settings")
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
    * [Negotiated-UC2] maximum success test
    */
    func testMqtt5NegotiatedSettingsMaximumSettings() throws {
        let inputHost = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_DIRECT_MQTT_HOST")
        let inputPort = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_DIRECT_MQTT_PORT")

        let sessionExpirtyInterval = TimeInterval(600000)
        let clientId = createClientId()
        let keepAliveInterval = TimeInterval(1000)

        let mqttConnectOptions = MqttConnectOptions(
            keepAliveInterval: keepAliveInterval,
            clientId: clientId,
            sessionExpiryInterval: sessionExpirtyInterval)

        let clientOptions = MqttClientOptions(
            hostName: inputHost,
            port: UInt32(inputPort)!,
            connectOptions: mqttConnectOptions)

        let testContext = MqttTestContext()
        let client = try createClient(clientOptions: clientOptions, testContext: testContext)
        try client.start()
        if testContext.semaphoreConnectionSuccess.wait(timeout: .now() + 5) == .timedOut {
            print("Connection Success Timed out after 5 seconds")
            XCTFail("Connection Timed Out")
        }

        if let negotiatedSettings = testContext.negotiatedSettings {
            XCTAssertEqual(negotiatedSettings.sessionExpiryInterval, sessionExpirtyInterval)
            XCTAssertEqual(negotiatedSettings.clientId, clientId)
            XCTAssertEqual(negotiatedSettings.serverKeepAlive, keepAliveInterval)
            XCTAssertEqual(negotiatedSettings.maximumQos, QoS.atLeastOnce)
        } else {
            XCTFail("Missing negotiated settings")
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
    * [Negotiated-UC3] server settings limit test
    */
    #if os(macOS) || os(Linux)
    func testMqtt5NegotiatedSettingsServerLimit() throws {
        let inputHost = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")
        let inputCert = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_CERT")
        let inputKey = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_KEY")

        let tlsOptions = try TLSContextOptions.makeMTLS(
            certificatePath: inputCert,
            privateKeyPath: inputKey
        )
        let tlsContext = try TLSContext(options: tlsOptions, mode: .client)

        let sessionExpiryInterval = TimeInterval(UInt32.max)
        let keepAliveInterval = TimeInterval(UInt16.max)
        let receiveMaximum = UInt16.max
        let maximumPacketSize = UInt32.max

        let mqttConnectOptions = MqttConnectOptions(
            keepAliveInterval: keepAliveInterval,
            sessionExpiryInterval: sessionExpiryInterval,
            receiveMaximum: receiveMaximum,
            maximumPacketSize: maximumPacketSize)

        let clientOptions = MqttClientOptions(
            hostName: inputHost,
            port: UInt32(8883),
            tlsCtx: tlsContext,
            connectOptions: mqttConnectOptions)

        let testContext = MqttTestContext()
        let client = try createClient(clientOptions: clientOptions, testContext: testContext)
        try client.start()
        if testContext.semaphoreConnectionSuccess.wait(timeout: .now() + 5) == .timedOut {
            print("Connection Success Timed out after 5 seconds")
            XCTFail("Connection Timed Out")
        }

        if let negotiatedSettings = testContext.negotiatedSettings {
            XCTAssertNotEqual(sessionExpiryInterval, negotiatedSettings.sessionExpiryInterval)
            XCTAssertNotEqual(receiveMaximum, negotiatedSettings.receiveMaximumFromServer)
            XCTAssertNotEqual(maximumPacketSize, negotiatedSettings.maximumPacketSizeToServer)
            XCTAssertNotEqual(keepAliveInterval, negotiatedSettings.serverKeepAlive)
        } else {
            XCTFail("Missing negotiated settings")
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
        // Wait on subscribe to make sure we subscribed to the topic before publish
        async let _ = try await client.subscribe(subscribePacket: subscribe)
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

    #endif
}
