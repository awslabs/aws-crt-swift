//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
import Foundation
import AwsCMqtt
@testable import AwsCommonRuntimeKit

enum MqttTestError: Error {
    case timeout
    case connectionFail
    case disconnectFail
    case stopFail
}

class Mqtt5ClientTests: XCBaseTestCase {

    /// start client and check for connection success
    func connectClient(client: Mqtt5Client, testContext: MqttTestContext) throws -> Void {
        try client.start()
        if testContext.semaphoreConnectionSuccess.wait(timeout: .now() + 5) == .timedOut {
            print("Connection Success Timed out after 5 seconds")
            XCTFail("Connection Timed Out")
            throw MqttTestError.connectionFail
        }
    }

    /// stop client and check for discconnection and stopped lifecycle events
    func disconnectClientCleanup(client: Mqtt5Client, testContext: MqttTestContext, disconnectPacket: DisconnectPacket? = nil) throws -> Void {
        try client.stop(disconnectPacket: disconnectPacket)
        defer{client.close()}

        if testContext.semaphoreDisconnection.wait(timeout: .now() + 5) == .timedOut {
            print("Disconnection timed out after 5 seconds")
            XCTFail("Disconnection timed out")
            throw MqttTestError.disconnectFail
        }

        if testContext.semaphoreStopped.wait(timeout: .now() + 5) == .timedOut {
            print("Stop timed out after 5 seconds")
            XCTFail("Stop timed out")
            throw MqttTestError.stopFail
        }
    }

    /// stop client and check for stopped lifecycle event
    func stopClient(client: Mqtt5Client, testContext: MqttTestContext) throws -> Void {
        try client.stop()
        if testContext.semaphoreStopped.wait(timeout: .now() + 5) == .timedOut {
            print("Stop timed out after 5 seconds")
            XCTFail("Stop timed out")
            throw MqttTestError.stopFail
        }
    }

    /// stop client and check for stopped lifecycle event
    func stopClientCleanup(client: Mqtt5Client, testContext: MqttTestContext) throws -> Void {
        try client.stop()
        defer{client.close()}
        if testContext.semaphoreStopped.wait(timeout: .now() + 5) == .timedOut {
            print("Stop timed out after 5 seconds")
            XCTFail("Stop timed out")
            throw MqttTestError.stopFail
        }
    }

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

        init(contextName: String = "",
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
                    print(contextName + " Mqtt5ClientTests: onPublishReceived. Topic:\'\(publishData.publishPacket.topic)\' QoS:\(publishData.publishPacket.qos) payload:\'\(payloadString)\'")
                } else {
                    print(contextName + " Mqtt5ClientTests: onPublishReceived. Topic:\'\(publishData.publishPacket.topic)\' QoS:\(publishData.publishPacket.qos)")
                }
                self.publishPacket = publishData.publishPacket
                self.semaphorePublishReceived.signal()
                self.publishCount += 1
                if self.publishCount == self.publishTarget {
                    self.semaphorePublishTargetReached.signal()
                }
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

        /// Setup a simple websocket transform function
        /// - `isSuccess`: True, complete the handshake with success
        ///             False, fail the handshake with error AWS_ERROR_UNSUPPORTED_OPERATION
        func withWebsocketTransform(isSuccess: Bool){
            self.onWebSocketHandshake = { httpRequest, completCallback in
                completCallback(httpRequest, isSuccess ? AWS_OP_SUCCESS : Int32(AWS_ERROR_UNSUPPORTED_OPERATION.rawValue))
            }
        }

        func withIoTSigv4WebsocketTransform(region: String, provider: CredentialsProvider){
            let signingConfig = SigningConfig(algorithm: SigningAlgorithmType.signingV4,
                                              signatureType: SignatureType.requestQueryParams,
                                              service: "iotdevicegateway",
                                              region: region,
                                              credentialsProvider: provider,
                                              omitSessionToken: true)


            self.onWebSocketHandshake = { httpRequest, completCallback in
                do
                {
                    let returnedHttpRequest = try await Signer.signRequest(request: httpRequest, config:signingConfig)
                    completCallback(returnedHttpRequest, AWS_OP_SUCCESS)
                }
                catch
                {
                    completCallback(httpRequest, Int32(AWS_ERROR_UNSUPPORTED_OPERATION.rawValue))
                }
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

    func compareEnums<T: Equatable>(arrayOne: [T], arrayTwo: [T]) throws {
        XCTAssertEqual(arrayOne.count, arrayTwo.count, "The arrays do not have the same number of elements")
        for i in 0..<arrayOne.count {
            XCTAssertEqual(arrayOne[i], arrayTwo[i], "The elements at index \(i) are not equal")
        }
    }

    func withTimeout<T>(client: Mqtt5Client, seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {

        let timeoutTask: () async throws -> T = {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw MqttTestError.timeout
        }

        var result: T?

        try await withThrowingTaskGroup(of: T.self) { group in
            // Start the operation
            group.addTask { try await operation() }
            // Start the timeout
            group.addTask { try await timeoutTask() }

            do {
                result = try await group.next()
                group.cancelAll()
            } catch {
                // Close the client to complete all operations that may be timing out
                client.close()
                throw MqttTestError.timeout
            }
        }

        return result!
    }

    let timeoutInterval = TimeInterval(5)

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
        mqtt5client.close()
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
                                            topicAliasingOptions: TopicAliasingOptions())
        XCTAssertNotNil(clientOptions)
        let context = MqttTestContext()
        let mqtt5client = try createClient(clientOptions: clientOptions, testContext: context)
        XCTAssertNotNil(mqtt5client)
        mqtt5client.close()
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
        try connectClient(client: client, testContext: testContext)
        try disconnectClientCleanup(client:client, testContext: testContext)
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
        try connectClient(client: client, testContext: testContext)
        try disconnectClientCleanup(client:client, testContext: testContext)
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
        try connectClient(client: client, testContext: testContext)
        try disconnectClientCleanup(client:client, testContext: testContext)
    }

    /*
     * [ConnDC-UC4] Direct Connection with mutual TLS
     */
    func testMqtt5DirectConnectWithMutualTLS() throws {
        try skipIfPlatformDoesntSupportTLS()
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
        try connectClient(client: client, testContext: testContext)
        try disconnectClientCleanup(client:client, testContext: testContext)
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
        try connectClient(client: client, testContext: testContext)
        try disconnectClientCleanup(client:client, testContext: testContext)
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
        try connectClient(client: client, testContext: testContext)
        try disconnectClientCleanup(client:client, testContext: testContext)
    }

    /*===============================================================
                     WEBSOCKET CONNECT TEST CASES
    =================================================================*/
    /*
     * [ConnWS-UC1] Happy path. Websocket connection with minimal configuration.
     */
    func testMqtt5WSConnectionMinimal() throws
    {
        let inputHost = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_WS_MQTT_HOST")
        let inputPort = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_WS_MQTT_PORT")

        let clientOptions = MqttClientOptions(
            hostName: inputHost,
            port: UInt32(inputPort)!)

        let testContext = MqttTestContext()
        testContext.withWebsocketTransform(isSuccess: true)
        let client = try createClient(clientOptions: clientOptions, testContext: testContext)
        try connectClient(client: client, testContext: testContext)
        try disconnectClientCleanup(client:client, testContext: testContext)
    }


    /*
     * [ConnWS-UC2]  websocket connection with basic authentication
     */
    func testMqtt5WSConnectWithBasicAuth() throws {

        let inputUsername = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_BASIC_AUTH_USERNAME")
        let inputPassword = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_BASIC_AUTH_PASSWORD")
        let inputHost = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_WS_MQTT_BASIC_AUTH_HOST")
        let inputPort = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_WS_MQTT_BASIC_AUTH_PORT")

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
        testContext.withWebsocketTransform(isSuccess: true)
        let client = try createClient(clientOptions: clientOptions, testContext: testContext)
        try connectClient(client: client, testContext: testContext)
        try disconnectClientCleanup(client:client, testContext: testContext)
    }


    /*
     * [ConnWS-UC3] websocket connection with TLS
     */
    func testMqtt5WSConnectWithTLS() throws {
        try skipIfPlatformDoesntSupportTLS()
        let inputHost = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_WS_MQTT_TLS_HOST")
        let inputPort = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_WS_MQTT_TLS_PORT")

        // XCode could only take terminal environment variable
        let tlsOptions = TLSContextOptions.makeDefault()
        tlsOptions.setVerifyPeer(false)
        let tlsContext = try TLSContext(options: tlsOptions, mode: .client)

        let clientOptions = MqttClientOptions(
            hostName: inputHost,
            port: UInt32(inputPort)!,
            tlsCtx: tlsContext)

        let testContext = MqttTestContext()
        testContext.withWebsocketTransform(isSuccess: true)

        let client = try createClient(clientOptions: clientOptions, testContext: testContext)
        try connectClient(client: client, testContext: testContext)
        try disconnectClientCleanup(client:client, testContext: testContext)
    }

    /*
     * [ConnWS-UC4] websocket connection with TLS, using sigv4
     */
    func testMqtt5WSConnectWithMutualTLS() throws {
        try skipIfPlatformDoesntSupportTLS()

        let inputHost = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")
        let region = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_REGION")

        let tlsOptions = TLSContextOptions.makeDefault()
        let tlsContext = try TLSContext(options: tlsOptions, mode: .client)

        let elg = try EventLoopGroup()
        let resolver = try HostResolver(eventLoopGroup: elg,
                                        maxHosts: 8,
                                        maxTTL: 30)
        let bootstrap = try ClientBootstrap(eventLoopGroup: elg, hostResolver: resolver)

        let clientOptions = MqttClientOptions(
            hostName: inputHost,
            port: UInt32(443),
            bootstrap: bootstrap,
            tlsCtx: tlsContext)

        // setup role credential
        let accessKey = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_ROLE_CREDENTIAL_ACCESS_KEY")
        let secret = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_ROLE_CREDENTIAL_SECRET_ACCESS_KEY")
        let sessionToken = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_ROLE_CREDENTIAL_SESSION_TOKEN")

        let provider = try CredentialsProvider(source: .static(accessKey: accessKey,
                                                               secret: secret,
                                                               sessionToken: sessionToken))
        let testContext = MqttTestContext()
        testContext.withIoTSigv4WebsocketTransform(region: region, provider: provider)

        let client = try createClient(clientOptions: clientOptions, testContext: testContext)
        testContext.onWebSocketHandshake = nil
        try connectClient(client: client, testContext: testContext)
        try disconnectClientCleanup(client:client, testContext: testContext)
    }

    /*
     * [ConnWS-UC5] Websocket connection with HttpProxy options
     */
    func testMqtt5WSConnectWithHttpProxy() throws {
        try skipIfPlatformDoesntSupportTLS()
        try skipifmacOS()

        let iotHost = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")
        let region = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_REGION")
        let httpHost = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_PROXY_HOST")
        let httpPort = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_PROXY_PORT")

        let tlsOptions = TLSContextOptions.makeDefault()
        let tlsContext = try TLSContext(options: tlsOptions, mode: .client)


        let elg = try EventLoopGroup()
        let resolver = try HostResolver(eventLoopGroup: elg,
                                        maxHosts: 8,
                                        maxTTL: 30)
        let bootstrap = try ClientBootstrap(eventLoopGroup: elg, hostResolver: resolver)
        let httpProxy = HTTPProxyOptions(hostName: httpHost, port: UInt32(httpPort)!, authType: .none, connectionType: HTTPProxyConnectionType.tunnel)

        let clientOptions = MqttClientOptions(
            hostName: iotHost,
            port: UInt32(443),
            bootstrap: bootstrap,
            tlsCtx: tlsContext,
            httpProxyOptions: httpProxy)

        let provider = try CredentialsProvider(source: .defaultChain(bootstrap: bootstrap,
                                                                     fileBasedConfiguration: FileBasedConfiguration(),
                                                                     tlsContext: tlsContext))
        let testContext = MqttTestContext()
        testContext.withIoTSigv4WebsocketTransform(region: region, provider: provider)


        let client = try createClient(clientOptions: clientOptions, testContext: testContext)
        testContext.onWebSocketHandshake = nil
        try connectClient(client: client, testContext: testContext)
        try disconnectClientCleanup(client:client, testContext: testContext)
    }


    /*
     * [ConnWS-UC5] Websocket connection with HttpProxy options
     */
    func testMqtt5WSConnectFull() throws {
        let inputHost = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_WS_MQTT_HOST")
        let inputPort = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_WS_MQTT_PORT")

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
        testContext.withWebsocketTransform(isSuccess: true)
        let client = try createClient(clientOptions: clientOptions, testContext: testContext)
        try connectClient(client: client, testContext: testContext)
        try disconnectClientCleanup(client:client, testContext: testContext)
    }


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
            return
        }

        if let failureData = testContext.lifecycleConnectionFailureData {
            XCTAssertEqual(failureData.crtError.code, Int32(AWS_IO_DNS_INVALID_NAME.rawValue))
        } else {
            XCTFail("lifecycleConnectionFailureData Missing")
            return
        }

        try stopClientCleanup(client: client, testContext: testContext)
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
            return
        }

        if let failureData = testContext.lifecycleConnectionFailureData {
            if failureData.crtError.code != Int32(AWS_IO_SOCKET_CONNECTION_REFUSED.rawValue) &&
               failureData.crtError.code != Int32(AWS_IO_SOCKET_TIMEOUT.rawValue) {
                XCTFail("Did not fail with expected error code")
                return
            }
        } else {
            XCTFail("lifecycleConnectionFailureData Missing")
            return
        }

        try stopClientCleanup(client: client, testContext: testContext)
    }

    /*
     * [ConnNegativeID-UC3] Client connect with invalid port for websocket connection
     */
    func testMqtt5WSInvalidPort() throws {
        let inputHost = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_DIRECT_MQTT_HOST")

        let clientOptions = MqttClientOptions(
            hostName: inputHost,
            port: 443)

        let testContext = MqttTestContext()
        testContext.withWebsocketTransform(isSuccess: true)
        let client = try createClient(clientOptions: clientOptions, testContext: testContext)

        try client.start()

        if testContext.semaphoreConnectionFailure.wait(timeout: .now() + 5) == .timedOut {
            print("Connection Failure Timed out after 5 seconds")
            XCTFail("Connection Timed Out")
            return
        }

        if let failureData = testContext.lifecycleConnectionFailureData {
            if failureData.crtError.code != Int32(AWS_IO_SOCKET_CONNECTION_REFUSED.rawValue) &&
               failureData.crtError.code != Int32(AWS_IO_SOCKET_TIMEOUT.rawValue) {
                XCTFail("Did not fail with expected error code")
                return
            }
        } else {
            XCTFail("lifecycleConnectionFailureData Missing")
            return
        }

        try stopClientCleanup(client: client, testContext: testContext)
    }

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
            return
        }

        if let failureData = testContext.lifecycleConnectionFailureData {
            XCTAssertEqual(failureData.crtError.code, Int32(AWS_IO_SOCKET_TIMEOUT.rawValue))
        } else {
            XCTFail("lifecycleConnectionFailureData Missing")
            return
        }

        try stopClientCleanup(client: client, testContext: testContext)
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
            return
        }

        if let failureData = testContext.lifecycleConnectionFailureData {
            XCTAssertEqual(failureData.crtError.code, Int32(AWS_ERROR_MQTT5_CONNACK_CONNECTION_REFUSED.rawValue))
        } else {
            XCTFail("lifecycleConnectionFailureData Missing")
            return
        }

        try stopClientCleanup(client: client, testContext: testContext)
    }

    /*
     * [ConnNegativeID-UC6] Client Websocket Handshake Failure test
     */
    func testMqtt5WSHandshakeFailure() throws {

        let inputHost = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_WS_MQTT_HOST")
        let inputPort = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_WS_MQTT_PORT")

        let clientOptions = MqttClientOptions(
            hostName: inputHost,
            port: UInt32(inputPort)!)

        let testContext = MqttTestContext()
        testContext.withWebsocketTransform(isSuccess: false)
        let client = try createClient(clientOptions: clientOptions, testContext: testContext)

        try client.start()

        if testContext.semaphoreConnectionFailure.wait(timeout: .now() + 5) == .timedOut {
            print("Connection Failure Timed out after 5 seconds")
            XCTFail("Connection Timed Out")
            return
        }

        if let failureData = testContext.lifecycleConnectionFailureData {
            if failureData.crtError.code != Int32(AWS_ERROR_UNSUPPORTED_OPERATION.rawValue) {
                XCTFail("Did not fail with expected error code")
                return
            }
        } else {
            XCTFail("lifecycleConnectionFailureData Missing")
            return
        }

        try stopClient(client: client, testContext: testContext)
    }


    /*
    * [ConnNegativeID-UC7] Double Client ID Failure test
    */
    func testMqtt5MTLSConnectDoubleClientIdFailure() throws {
        try skipIfPlatformDoesntSupportTLS()
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
        try connectClient(client: client, testContext: testContext)

        // Create a second client with the same client id
        let testContext2 = MqttTestContext(contextName: "client2")
        let client2 = try createClient(clientOptions: clientOptions, testContext: testContext2)

        // Connect with second client
        try connectClient(client: client2, testContext: testContext2)

        if testContext.semaphoreDisconnection.wait(timeout: .now() + 5) == .timedOut {
            print("Disconnection due to duplicate client id timed out on client1")
            XCTFail("Disconnection Timed Out")
            return
        }

        if let disconnectionData = testContext.lifecycleDisconnectionData {
            print(disconnectionData.crtError)
            if let disconnectionPacket = disconnectionData.disconnectPacket {
                XCTAssertEqual(disconnectionPacket.reasonCode, DisconnectReasonCode.sessionTakenOver)
            } else {
                XCTFail("DisconnectPacket missing")
                return
            }
        } else {
            XCTFail("lifecycleDisconnectionData Missing")
            return
        }

        try stopClientCleanup(client: client, testContext: testContext)
        try disconnectClientCleanup(client: client2, testContext: testContext2)
    }

    /*===============================================================
                     NEGATIVE DATA INPUT TESTS
    =================================================================*/
    /*
    * [NewNegative-UC1] Negative Connect Packet Properties
    */
    func testMqtt5NegativeConnectPacket() throws {
        do {
            let connectOptions = MqttConnectOptions(keepAliveInterval: TimeInterval(-1))
            let clientOptions = MqttClientOptions(hostName: "localhost",
                                              port: UInt32(8883),
                                              connectOptions: connectOptions)

            let _ = try Mqtt5Client(clientOptions: clientOptions)
            XCTFail("Negative keepAliveInterval didn't throw an error.")
            return
        }
        catch {
            print("expected keepAliveInterval error: \(error)")
        }

        do {
            let connectOptions = MqttConnectOptions(sessionExpiryInterval: TimeInterval(-1))
            let clientOptions = MqttClientOptions(hostName: "localhost",
                                              port: UInt32(8883),
                                              connectOptions: connectOptions)
            let _ = try Mqtt5Client(clientOptions: clientOptions)
            XCTFail("Negative sessionExpiryInterval didn't throw an error.")
            return
        } catch {
            print("expected sessionExpirtyInterval error: \(error)")
        }

        do {
            let connectOptions = MqttConnectOptions(willDelayInterval: -1)
            let clientOptions = MqttClientOptions(hostName: "localhost",
                                              port: UInt32(8883),
                                              connectOptions: connectOptions)
            let _ = try Mqtt5Client(clientOptions: clientOptions)
            XCTFail("Negative willDelayInterval didn't throw an error.")
            return
        } catch {
            print("expected willDelayInterval error: \(error)")
        }

        do {
            let clientOptions = MqttClientOptions(hostName: "localhost",
                                              port: UInt32(8883),
                                              minReconnectDelay: -1)
            let _ = try Mqtt5Client(clientOptions: clientOptions)
            XCTFail("Negative minReconnectDelay didn't throw an error.")
            return
        } catch {
            print("expected minReconnectDelay error: \(error)")
        }

        do {
            let clientOptions = MqttClientOptions(hostName: "localhost",
                                              port: UInt32(8883),
                                              maxReconnectDelay: -1)
            let _ = try Mqtt5Client(clientOptions: clientOptions)
            XCTFail("Negative maxReconnectDelay didn't throw an error.")
            return
        } catch {
            print("expected minReconnectDelay error: \(error)")
        }

        do {
            let clientOptions = MqttClientOptions(hostName: "localhost",
                                              port: UInt32(8883),
                                              minConnectedTimeToResetReconnectDelay: -1)
            let _ = try Mqtt5Client(clientOptions: clientOptions)
            XCTFail("Negative minConnectedTimeToResetReconnectDelay didn't throw an error.")
            return
        } catch {
            print("expected minConnectedTimeToResetReconnectDelay error: \(error)")
        }

        do {
            let clientOptions = MqttClientOptions(hostName: "localhost",
                                              port: UInt32(8883),
                                              pingTimeout: -1)
            let _ = try Mqtt5Client(clientOptions: clientOptions)
            XCTFail("Negative pingTimeout didn't throw an error.")
            return
        } catch {
            print("expected pingTimeout error: \(error)")
        }

        do {
            let clientOptions = MqttClientOptions(hostName: "localhost",
                                              port: UInt32(8883),
                                              connackTimeout: -1)
            let _ = try Mqtt5Client(clientOptions: clientOptions)
            XCTFail("Negative connackTimeout didn't throw an error.")
            return
        } catch {
            print("expected connackTimeout error: \(error)")
        }

        do {
            let clientOptions = MqttClientOptions(hostName: "localhost",
                                              port: UInt32(8883),
                                              ackTimeout: -1)
            let _ = try Mqtt5Client(clientOptions: clientOptions)
            XCTFail("Negative ackTimeout didn't throw an error.")
            return
        } catch {
            print("expected ackTimeout error: \(error)")
        }
    }

    /*
    * [NewNegative-UC2] Negative Disconnect Packet Properties
    */
    func testMqtt5NegativeDisconnectPacket() async throws {
        try skipIfPlatformDoesntSupportTLS()
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
        defer { client.close() }
        try connectClient(client: client, testContext: testContext)

        let disconnectPacket = DisconnectPacket(sessionExpiryInterval: -1)
        do {
            try client.stop(disconnectPacket: disconnectPacket)
            XCTFail("Negative sessionExpiryInterval didn't throw an error.")
            return
        } catch {
            print("expected sessionExpiryInterval error: \(error)")
        }
    }

    /*
    * [NewNegative-UC3] Negative Publish Packet Properties
    */
    func testMqtt5NegativePublishPacket() async throws {
        try skipIfPlatformDoesntSupportTLS()
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
        defer { client.close() }
        try connectClient(client: client, testContext: testContext)

        let publishPacket = PublishPacket(qos: .atMostOnce,
                                          topic: "Test/Topic",
                                          messageExpiryInterval: -1)

        do {
            let _ = try await client.publish(publishPacket: publishPacket)
            XCTFail("Negative messageExpiryInterval didn't throw an error.")
            return
        } catch {
            print("expected messageExpiryInterval error: \(error)")
        }
    }

    /*
    * [NewNegative-UC4] Negative Subscribe Packet Properties (Swift does not allow a negative subscriptionIdentifier)
    */

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
        try connectClient(client: client, testContext: testContext)

        if let negotiatedSettings = testContext.negotiatedSettings {
            XCTAssertEqual(negotiatedSettings.sessionExpiryInterval, sessionExpirtyInterval)
        } else {
            XCTFail("Missing negotiated settings")
            return
        }

        try disconnectClientCleanup(client: client, testContext: testContext)
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
        try connectClient(client: client, testContext: testContext)

        if let negotiatedSettings = testContext.negotiatedSettings {
            XCTAssertEqual(negotiatedSettings.sessionExpiryInterval, sessionExpirtyInterval)
            XCTAssertEqual(negotiatedSettings.clientId, clientId)
            XCTAssertEqual(negotiatedSettings.serverKeepAlive, keepAliveInterval)
            XCTAssertEqual(negotiatedSettings.maximumQos, QoS.atLeastOnce)
        } else {
            XCTFail("Missing negotiated settings")
            return
        }

        try disconnectClientCleanup(client: client, testContext: testContext)
    }

    /*
    * [Negotiated-UC3] server settings limit test
    */
    func testMqtt5NegotiatedSettingsServerLimit() throws {
        try skipIfPlatformDoesntSupportTLS()
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
        try connectClient(client: client, testContext: testContext)

        if let negotiatedSettings = testContext.negotiatedSettings {
            XCTAssertNotEqual(sessionExpiryInterval, negotiatedSettings.sessionExpiryInterval)
            XCTAssertNotEqual(receiveMaximum, negotiatedSettings.receiveMaximumFromServer)
            XCTAssertNotEqual(maximumPacketSize, negotiatedSettings.maximumPacketSizeToServer)
            XCTAssertNotEqual(keepAliveInterval, negotiatedSettings.serverKeepAlive)
        } else {
            XCTFail("Missing negotiated settings")
            return
        }

        try disconnectClientCleanup(client: client, testContext: testContext)
    }

    /*===============================================================
                     OPERATION TESTS
    =================================================================*/
    /*
    * [Op-UC1] Sub-Unsub happy path
    */
    func testMqtt5SubUnsub() async throws {
        try skipIfPlatformDoesntSupportTLS()
        let inputHost = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_DIRECT_MQTT_HOST")
        let inputPort = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_DIRECT_MQTT_PORT")


        let clientId = createClientId()

        let connectOptions = MqttConnectOptions(clientId: clientId)

        let clientOptions = MqttClientOptions(
            hostName: inputHost,
            port: UInt32(inputPort)!)

      let testContext = MqttTestContext(publishTarget: 10)
        let client = try createClient(clientOptions: clientOptions, testContext: testContext)
        try connectClient(client: client, testContext: testContext)

        let topic = "test/MQTT5_Binding_Swift_" + UUID().uuidString
        let subscribePacket = SubscribePacket(topicFilter: topic, qos: QoS.atLeastOnce, noLocal: false)

        let subackPacket: SubackPacket =
            try await withTimeout(client: client, seconds: 2, operation: {
                try await client.subscribe(subscribePacket: subscribePacket)
            })
        print("SubackPacket received with result \(subackPacket.reasonCodes[0])")

        for index in 1...10 {
            print("publish for \(index) time(s)")
            let publishPacket = PublishPacket(qos: QoS.atLeastOnce, topic: topic, payload: "Hello World \(index)".data(using: .utf8))
            let _ = try await client.publish(publishPacket: publishPacket)
        }
        testContext.semaphorePublishTargetReached.wait()
        try disconnectClientCleanup(client:client, testContext: testContext)
    }

    /*
    * [Op-UC2] Will test
    */
    func testMqtt5WillTest() async throws {
        try skipIfPlatformDoesntSupportTLS()
        let inputHost = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")
        let inputCert = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_CERT")
        let inputKey = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_KEY")

        let tlsOptions = try TLSContextOptions.makeMTLS(
            certificatePath: inputCert,
            privateKeyPath: inputKey
        )
        let tlsContext = try TLSContext(options: tlsOptions, mode: .client)

        let clientIDPublisher = createClientId() + "Publisher"
        let topic = "test/MQTT5_Binding_Swift_" + UUID().uuidString
        let willPacket = PublishPacket(qos: .atLeastOnce, topic: topic, payload: "TEST WILL".data(using: .utf8))

        let connectOptionsPublisher = MqttConnectOptions(clientId: clientIDPublisher, will: willPacket)
        let clientOptions = MqttClientOptions(
            hostName: inputHost,
            port: UInt32(8883),
            tlsCtx: tlsContext,
            connectOptions: connectOptionsPublisher)

        let testContextPublisher = MqttTestContext(contextName: "Publisher")
        let clientPublisher = try createClient(clientOptions: clientOptions, testContext: testContextPublisher)
        try connectClient(client: clientPublisher, testContext: testContextPublisher)

        let clientIDSubscriber = createClientId() + "Subscriber"
        let testContextSubscriber = MqttTestContext(contextName: "Subscriber")
        let connectOptionsSubscriber = MqttConnectOptions(clientId: clientIDSubscriber)
        let clientOptionsSubscriber = MqttClientOptions(
            hostName: inputHost,
            port: UInt32(8883),
            tlsCtx: tlsContext,
            connectOptions: connectOptionsSubscriber)

        let clientSubscriber = try createClient(clientOptions: clientOptionsSubscriber, testContext: testContextSubscriber)
        try connectClient(client: clientSubscriber, testContext: testContextSubscriber)

        let subscribePacket = SubscribePacket(topicFilter: topic, qos: QoS.atLeastOnce, noLocal: false)
        let subackPacket: SubackPacket =
            try await withTimeout(client: clientSubscriber, seconds: 2, operation: {
                try await clientSubscriber.subscribe(subscribePacket: subscribePacket)
            })
        print("SubackPacket received with result \(subackPacket.reasonCodes[0])")

        let disconnectPacket = DisconnectPacket(reasonCode: .disconnectWithWillMessage)
        try disconnectClientCleanup(client: clientPublisher, testContext: testContextPublisher, disconnectPacket: disconnectPacket)

        if testContextSubscriber.semaphorePublishReceived.wait(timeout: .now() + 5) == .timedOut {
            print("Publish not received after 5 seconds")
            XCTFail("Publish packet not received on subscribed topic")
            return
        }

        try disconnectClientCleanup(client:clientSubscriber, testContext: testContextSubscriber)
    }

    /*
    * [Op-UC3] Binary Publish Test
    */
    func testMqtt5BinaryPublish() async throws {
        try skipIfPlatformDoesntSupportTLS()
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
        try connectClient(client: client, testContext: testContext)

        let topic = "test/MQTT5_Binding_Swift_" + UUID().uuidString
        let subscribePacket = SubscribePacket(topicFilter: topic, qos: QoS.atLeastOnce, noLocal: false)

        _ = try await withTimeout(client: client, seconds: 2, operation: {
                try await client.subscribe(subscribePacket: subscribePacket)
            })

        let payloadData = Data((0..<256).map { _ in UInt8.random(in: 0...255) })
        let publishPacket = PublishPacket(qos: QoS.atLeastOnce, topic: topic, payload: payloadData)

        let publishResult: PublishResult =
            try await withTimeout(client: client, seconds: 2, operation: {
                try await client.publish(publishPacket: publishPacket)
            })

        if publishResult.puback == nil {
            XCTFail("Puback missing.")
            return
        }

        if testContext.semaphorePublishReceived.wait(timeout: .now() + 5) == .timedOut {
            print("Publish not received after 5 seconds")
            XCTFail("Publish packet not received on subscribed topic")
            return
        }

        let publishReceived = testContext.publishPacket!
        XCTAssertEqual(publishReceived.payload, payloadData, "Binary data received as publish not equal to binary data used to generate publish")

        try disconnectClientCleanup(client: client, testContext: testContext)
    }

    /*
    * [Op-UC4] Multi-sub unsub
    */
    func testMqtt5SubUnsub() async throws {
        try skipIfPlatformDoesntSupportTLS()
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
        try connectClient(client: client, testContext: testContext)
        
        let topic = "test/MQTT5_Binding_Swift_" + UUID().uuidString
        let subscribePacket = SubscribePacket(topicFilter: topic, qos: QoS.atLeastOnce, noLocal: false)
        let subackPacket: SubackPacket =
        try await withTimeout(client: client, seconds: 2, operation: {
            try await client.subscribe(subscribePacket: subscribePacket)
        })
        print("SubackPacket received with result \(subackPacket.reasonCodes[0])")
        
        let publishPacket = PublishPacket(qos: QoS.atLeastOnce, topic: topic, payload: "Hello World".data(using: .utf8))
        let publishResult: PublishResult =
        try await withTimeout(client: client, seconds: 2, operation: {
            try await client.publish(publishPacket: publishPacket)
        })
        
        if let puback = publishResult.puback {
            print("PubackPacket received with result \(puback.reasonCode)")
        } else {
            XCTFail("PublishResult missing.")
            return
        }
        
        if testContext.semaphorePublishReceived.wait(timeout: .now() + 5) == .timedOut {
            print("Publish not received after 5 seconds")
            XCTFail("Publish packet not received on subscribed topic")
            return
        }
        
        let unsubscribePacket = UnsubscribePacket(topicFilter: topic)
        let unsubackPacket: UnsubackPacket =
        try await withTimeout(client: client, seconds: 2, operation: {
            try await client.unsubscribe(unsubscribePacket: unsubscribePacket)
        })
        print("UnsubackPacket received with result \(unsubackPacket.reasonCodes[0])")
        
        try disconnectClientCleanup(client: client, testContext: testContext)
    }

    /*===============================================================
                     ERROR OPERATION TESTS
    =================================================================*/
    /*
    * [ErrorOp-UC1] Null Publish Test (Swift does not allow a nil PublishPacket)
    * [ErrorOp-UC2] Null Subscribe Test (Swift does not allow a nil SubscribePacket)
    * [ErrorOp-UC3] Null Unsubscribe Test (Swift does not allow a nil UnsubscribePacket)
    */

    /*
    * [ErrorOp-UC4] Invalid Topic Publish
    */
    func testMqtt5InvalidPublishTopic() async throws {

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
        try connectClient(client: client, testContext: testContext)

        let publishPacket = PublishPacket(qos: .atLeastOnce, topic: "")
        do {
            _ = try await client.publish(publishPacket: publishPacket)
        } catch CommonRunTimeError.crtError(let crtError) {
            XCTAssertEqual(crtError.code, Int32(AWS_ERROR_MQTT5_PUBLISH_OPTIONS_VALIDATION.rawValue))
        }

        try disconnectClientCleanup(client:client, testContext: testContext)
    }

    /*
    * [ErrorOp-UC5] Invalid Topic Subscribe
    */
    func testMqtt5InvalidSubscribeTopic() async throws {

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
        try connectClient(client: client, testContext: testContext)

        let subscribePacket = SubscribePacket(topicFilter: "", qos: .atLeastOnce)
        do {
            _ = try await client.subscribe(subscribePacket: subscribePacket)
        } catch CommonRunTimeError.crtError(let crtError) {
            XCTAssertEqual(crtError.code, Int32(AWS_ERROR_MQTT5_SUBSCRIBE_OPTIONS_VALIDATION.rawValue))
        }

        try disconnectClientCleanup(client:client, testContext: testContext)
    }

    /*
    * [ErrorOp-UC6] Invalid Topic Unsubscribe
    */
    func testMqtt5InvalidUnsubscribeTopic() async throws {

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
        try connectClient(client: client, testContext: testContext)

        let unsubscribePacket = UnsubscribePacket(topicFilter: "")
        do {
            _ = try await client.unsubscribe(unsubscribePacket: unsubscribePacket)
        } catch CommonRunTimeError.crtError(let crtError) {
            XCTAssertEqual(crtError.code, Int32(AWS_ERROR_MQTT5_UNSUBSCRIBE_OPTIONS_VALIDATION.rawValue))
        }

        try disconnectClientCleanup(client:client, testContext: testContext)
    }

    /*===============================================================
                     QOS1 TESTS
    =================================================================*/
    /*
    * [QoS1-UC1] Happy Path
    */
    func testMqtt5QoS1HappyPath() async throws {
        try skipIfPlatformDoesntSupportTLS()
        let inputHost = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")
        let inputCert = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_CERT")
        let inputKey = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_KEY")

        // Create and connect client1
        let tlsOptions = try TLSContextOptions.makeMTLS(
            certificatePath: inputCert,
            privateKeyPath: inputKey
        )
        let tlsContext = try TLSContext(options: tlsOptions, mode: .client)
        tlsOptions.setVerifyPeer(false)
        let connectOptions1 = MqttConnectOptions(clientId: createClientId())
        let clientOptions1 = MqttClientOptions(
            hostName: inputHost,
            port: UInt32(8883),
            tlsCtx: tlsContext,
            connectOptions: connectOptions1)
        let testContext1 = MqttTestContext()
        let client1 = try createClient(clientOptions: clientOptions1, testContext: testContext1)
        try connectClient(client: client1, testContext: testContext1)

        // Create and connect client2
        let connectOptions2 = MqttConnectOptions(clientId: createClientId())
        let clientOptions2 = MqttClientOptions(
            hostName: inputHost,
            port: UInt32(8883),
            tlsCtx: tlsContext,
            connectOptions: connectOptions2)
        let testContext2 = MqttTestContext(publishTarget: 10)
        let client2 = try createClient(clientOptions: clientOptions2, testContext: testContext2)
        try connectClient(client: client2, testContext: testContext2)

        let topic = "test/MQTT5_Binding_Swift_" + UUID().uuidString
        let subscribePacket = SubscribePacket(topicFilter: topic, qos: QoS.atLeastOnce, noLocal: false)

        _ = try await withTimeout(client: client2, seconds: 2, operation: {
                try await client2.subscribe(subscribePacket: subscribePacket)
            })

        // Send 10 publishes from client1
        var i = 1
        for _ in 1...10 {
            let publishPacket = PublishPacket(qos: .atLeastOnce,
                                              topic: topic,
                                              payload: "Test Publish: \(i)".data(using: .utf8))
            print("sending publish \(i)")
            _ = try await client1.publish(publishPacket: publishPacket)
            i += 1
        }

        // Wait for client2 to receive 10 publishes
        if testContext2.semaphorePublishTargetReached.wait(timeout: .now() + 10) == .timedOut {
            print("Expected Publish receive target not hit after 10 seconds")
            XCTFail("Missing Publishes")
            return
        }

        try disconnectClientCleanup(client:client1, testContext: testContext1)
        try disconnectClientCleanup(client:client2, testContext: testContext2)

    }

    /*===============================================================
                     RETAIN TESTS
    =================================================================*/
    /*
    * [Retain-UC1] Set and Clear
    */

    func testMqtt5Retain() async throws {
        try skipIfPlatformDoesntSupportTLS()
        let inputHost = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")
        let inputCert = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_CERT")
        let inputKey = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_KEY")

        // Create and connect client1
        let tlsOptions = try TLSContextOptions.makeMTLS(
            certificatePath: inputCert,
            privateKeyPath: inputKey
        )
        let tlsContext = try TLSContext(options: tlsOptions, mode: .client)
        tlsOptions.setVerifyPeer(false)
        let connectOptions1 = MqttConnectOptions(clientId: createClientId())
        let clientOptions1 = MqttClientOptions(
            hostName: inputHost,
            port: UInt32(8883),
            tlsCtx: tlsContext,
            connectOptions: connectOptions1)
        let testContext1 = MqttTestContext(contextName: "Client1")
        let client1 = try createClient(clientOptions: clientOptions1, testContext: testContext1)
        try connectClient(client: client1, testContext: testContext1)

        // Create client2
        let connectOptions2 = MqttConnectOptions(clientId: createClientId())
        let clientOptions2 = MqttClientOptions(
            hostName: inputHost,
            port: UInt32(8883),
            tlsCtx: tlsContext,
            connectOptions: connectOptions2)
        let testContext2 = MqttTestContext(contextName: "Client2")
        let client2 = try createClient(clientOptions: clientOptions2, testContext: testContext2)

        // Create client3
        let connectOptions3 = MqttConnectOptions(clientId: createClientId())
        let clientOptions3 = MqttClientOptions(
            hostName: inputHost,
            port: UInt32(8883),
            tlsCtx: tlsContext,
            connectOptions: connectOptions3)
        let testContext3 = MqttTestContext(contextName: "Client3")
        let client3 = try createClient(clientOptions: clientOptions3, testContext: testContext3)

        let topic = "test/MQTT5_Binding_Swift_" + UUID().uuidString
        let publishPacket = PublishPacket(qos: .atLeastOnce,
                                          topic: topic,
                                          payload: "Retained publish from client 1".data(using: .utf8),
                                          retain: true)
        let subscribePacket = SubscribePacket(topicFilter: topic,
                                              qos: QoS.atLeastOnce,
                                              noLocal: false)

        // publish retained message from client1
        let publishResult: PublishResult =
            try await withTimeout(client: client1, seconds: 2, operation: {
                try await client1.publish(publishPacket: publishPacket)
            })

        if let puback = publishResult.puback {
            print("PubackPacket received with result \(puback.reasonCode)")
        } else {
            XCTFail("PublishResult missing.")
            return
        }

        // connect client2 and subscribe to topic with retained client1 publish
        try connectClient(client: client2, testContext: testContext2)
        _ = try await withTimeout(client: client2, seconds: 2, operation: {
                try await client2.subscribe(subscribePacket: subscribePacket)
            })

        if testContext2.semaphorePublishReceived.wait(timeout: .now() + 10) == .timedOut {
            XCTFail("Expected retained Publish not received")
            return
        }

        XCTAssertEqual(testContext2.publishPacket?.payloadAsString(), publishPacket.payloadAsString())

        // Send an empty publish from client1 to clear the retained publish on the topic
        let publishPacketEmpty = PublishPacket(qos: .atLeastOnce, topic: topic, retain: true)
        // publish retained message from client1
        let publishResult2: PublishResult =
            try await withTimeout(client: client1, seconds: 2, operation: {
                try await client1.publish(publishPacket: publishPacketEmpty)
            })
        if let puback2 = publishResult2.puback {
            print("PubackPacket received with result \(puback2.reasonCode)")
        } else {
            XCTFail("PublishResult missing.")
            return
        }

        // connect client3 and subscribe to topic to insure there is no client1 retained publish
        try connectClient(client: client3, testContext: testContext3)

        _ = try await withTimeout(client: client3, seconds: 2, operation: {
                try await client3.subscribe(subscribePacket: subscribePacket)
            })

        if testContext3.semaphorePublishReceived.wait(timeout: .now() + 1) == .timedOut {
            print("no retained publish from client1")
        } else {
            XCTFail("Retained publish from client1 received when it should be cleared")
            return
        }

        try disconnectClientCleanup(client:client1, testContext: testContext1)
        try disconnectClientCleanup(client:client2, testContext: testContext2)
        try disconnectClientCleanup(client:client3, testContext: testContext3)
    }

    /*===============================================================
                     BINDING CLEANUP TESTS
    =================================================================*/
    /*
    * [BCT-UC1] Start Without Stop
    */
    func testStartWithoutStop() async throws {
        let inputHost = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_DIRECT_MQTT_HOST")
        let inputPort = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_DIRECT_MQTT_PORT")

        let clientOptions = MqttClientOptions(
            hostName: inputHost,
            port: UInt32(inputPort)!)

        let testContext = MqttTestContext()
        let client = try createClient(clientOptions: clientOptions, testContext: testContext)
        try connectClient(client: client, testContext: testContext)
        // close is required for client cleanup
        client.close()
    }

    /*
    * [BCT-UC2] Offline Operations
    */
    func testOfflineOperations() async throws {
        let inputHost = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_DIRECT_MQTT_HOST")
        let inputPort = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_DIRECT_MQTT_PORT")

        let clientOptions = MqttClientOptions(
            hostName: inputHost,
            port: UInt32(inputPort)!)


        let testContext = MqttTestContext()
        let client = try createClient(clientOptions: clientOptions, testContext: testContext)
        try connectClient(client: client, testContext: testContext)
        try stopClient(client: client, testContext: testContext)

        let topic = "test/MQTT5_Binding_Swift_" + UUID().uuidString
        let subscribePacket = PublishPacket(qos: QoS.atLeastOnce, topic: topic)
        async let _ = try? client.publish(publishPacket: subscribePacket)

        client.close()
    }
}
