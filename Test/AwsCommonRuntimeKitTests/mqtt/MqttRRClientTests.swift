//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
import Foundation
import AwsCMqtt
@testable import AwsCommonRuntimeKit

class Mqtt5RRClientTests: XCBaseTestCase {
    
    class MqttRRTestContext : @unchecked Sendable {
        let contextName: String

        // rr client context
        var responsePaths: [ResponsePath]?
        var correlationToken: String?
        var payload: Data?
        var subscriptionStatusEvent: SubscriptionStatusEvent?
        
        // rr events expectations
        var subscriptionStatusSuccessExpectation: XCTestExpectation
        var subscriptionStatusErrorExpectation: XCTestExpectation
        var onSubscriptionStatusUpdate : SubscriptionStatusEventHandler?
        
        
        // protocol client context
        var publishReceivedExpectation: XCTestExpectation
        var publishTargetReachedExpectation: XCTestExpectation
        var connectionSuccessExpectation: XCTestExpectation
        var connectionFailureExpectation: XCTestExpectation
        var disconnectionExpectation: XCTestExpectation
        var stoppedExpecation: XCTestExpectation

        var onPublishReceived: OnPublishReceived?
        var onLifecycleEventStopped: OnLifecycleEventStopped?
        var onLifecycleEventAttemptingConnect: OnLifecycleEventAttemptingConnect?
        var onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess?
        var onLifecycleEventConnectionFailure: OnLifecycleEventConnectionFailure?
        var onLifecycleEventDisconnection: OnLifecycleEventDisconnection?
        var onWebSocketHandshake: OnWebSocketHandshakeIntercept?
        
        init(contextName : String = "MqttClient"){
            self.contextName = contextName
            
            self.subscriptionStatusSuccessExpectation = XCTestExpectation(description: "Expect streaming operation publish status success.")
            self.subscriptionStatusErrorExpectation = XCTestExpectation(description: "Expect streaming operation publish status error.")
            self.publishReceivedExpectation = XCTestExpectation(description: "Expect publish received.")
            self.publishTargetReachedExpectation = XCTestExpectation(description: "Expect publish target reached")
            self.connectionSuccessExpectation = XCTestExpectation(description: "Expect connection Success")
            self.connectionFailureExpectation = XCTestExpectation(description: "Expect connection Failure")
            self.disconnectionExpectation = XCTestExpectation(description: "Expect disconnect")
            self.stoppedExpecation = XCTestExpectation(description: "Expect stopped")
            
            self.onSubscriptionStatusUpdate = { [self] statusEvent in
                print(contextName + "MqttRRClientTests: onSubscriptionStatusUpdate. EventType: \(statusEvent.event) ErrorCode:\( statusEvent.error!.code)")
                self.subscriptionStatusEvent = statusEvent
                if statusEvent.event == SubscriptionStatusEventType.established {
                    self.subscriptionStatusSuccessExpectation.fulfill()
                }else
                {
                    self.subscriptionStatusErrorExpectation.fulfill()
                }
            }
            
            self.onPublishReceived = { [self] publishData in
                if let payloadString = publishData.publishPacket.payloadAsString() {
                    print(contextName + " MqttRRClientTests: onPublishReceived. Topic:\'\(publishData.publishPacket.topic)\' QoS:\(publishData.publishPacket.qos) payload:\'\(payloadString)\'")
                } else {
                    print(contextName + " MqttRRClientTests: onPublishReceived. Topic:\'\(publishData.publishPacket.topic)\' QoS:\(publishData.publishPacket.qos)")
                }
                self.publishReceivedExpectation.fulfill()
            }

            self.onLifecycleEventStopped = { [self] _ in
                print(contextName + " MqttRRClientTests: onLifecycleEventStopped")
                self.stoppedExpecation.fulfill()
            }
            
            self.onLifecycleEventAttemptingConnect = { _ in
                print(contextName + " MqttRRClientTests: onLifecycleEventAttemptingConnect")
            }
            
            self.onLifecycleEventConnectionSuccess = { [self] successData in
                print(contextName + " MqttRRClientTests: onLifecycleEventConnectionSuccess")
                self.connectionSuccessExpectation.fulfill()
            }
            
            self.onLifecycleEventConnectionFailure = { [self] failureData in
                print(contextName + " MqttRRClientTests: onLifecycleEventConnectionFailure")
                self.connectionFailureExpectation.fulfill()
            }
            self.onLifecycleEventDisconnection = { [self] disconnectionData in
                print(contextName + " MqttRRClientTests: onLifecycleEventDisconnection")
                self.disconnectionExpectation.fulfill()
            }
        }
        
        // release the context before exit the test case
        func cleanup(){
            self.responsePaths = nil
        }
    }
    
    func createMqtt5Client(testContext: MqttRRTestContext) throws -> Mqtt5Client {
        try skipIfPlatformDoesntSupportTLS()
        let inputHost = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")
        let inputCert = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_CERT")
        let inputKey = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_KEY")
        
        let elg = try EventLoopGroup()
        let resolver = try HostResolver(eventLoopGroup: elg,
            maxHosts: 8,
            maxTTL: 30)
        let clientBootstrap = try ClientBootstrap(
            eventLoopGroup: elg,
            hostResolver: resolver)
        let socketOptions = SocketOptions()
        
        let tlsOptions = try TLSContextOptions.makeMTLS(
            certificatePath: inputCert,
            privateKeyPath: inputKey
        )
        let tlsContext = try TLSContext(options: tlsOptions, mode: .client)

        let clientOptionsWithCallbacks = MqttClientOptions(
            hostName: inputHost,
            port: 8883,
            bootstrap: clientBootstrap,
            socketOptions: socketOptions,
            tlsCtx: tlsContext,
            onPublishReceivedFn: testContext.onPublishReceived,
            onLifecycleEventStoppedFn: testContext.onLifecycleEventStopped,
            onLifecycleEventAttemptingConnectFn: testContext.onLifecycleEventAttemptingConnect,
            onLifecycleEventConnectionSuccessFn: testContext.onLifecycleEventConnectionSuccess,
            onLifecycleEventConnectionFailureFn: testContext.onLifecycleEventConnectionFailure,
            onLifecycleEventDisconnectionFn: testContext.onLifecycleEventDisconnection)

        let mqtt5Client = try Mqtt5Client(clientOptions: clientOptionsWithCallbacks)
        XCTAssertNotNil(mqtt5Client)
        return mqtt5Client
    }
    
    // MARK: - helper function
    
    // start client and check for connection success
    func startClient(client: Mqtt5Client, testContext: MqttRRTestContext) async throws{
        try client.start()
        await awaitExpectation([testContext.connectionSuccessExpectation], 5)
        
    }

    // stop client and check for discconnection and stopped lifecycle events
    func stopClient(client: Mqtt5Client, testContext: MqttRRTestContext, disconnectPacket: DisconnectPacket? = nil) async throws -> Void {
        try client.stop(disconnectPacket: disconnectPacket)
        return await awaitExpectation([testContext.stoppedExpecation], 5)
    }
    
    // setup rr client
    func setupRequestResponseClient(testContext: MqttRRTestContext) async throws -> MqttRequestResponseClient {
        let mqtt5Client = try createMqtt5Client(testContext: testContext)
        let rrClient = try MqttRequestResponseClient.newFromMqtt5Client(mqtt5Client: mqtt5Client, options: MqttRequestResponseClientOptions(operationTimeout: 10))

        // start the client
        try await startClient(client: mqtt5Client, testContext: testContext)
        return rrClient
    }
    
    // create a get rr request
    func createRequestResponseGetOptions(testContext: MqttRRTestContext , shadowName : String = UUID().uuidString, thingName: String, withCorrelationToken: Bool = true, publishTopic: String? = nil) -> RequestResponseOperationOptions {
        let subscriptionTopicFilter = "$aws/things/\(thingName)/shadow/name/\(shadowName)/get/+"
        let acceptedTopic = "$aws/things/\(thingName)/shadow/name/\(shadowName)/get/accepted"
        let rejectedTopic = "$aws/things/\(thingName)/shadow/name/\(shadowName)/get/rejected"
        let publishTopic = publishTopic ?? "$aws/things/\(thingName)/shadow/name/\(shadowName)/get"
                
        var payload = String("{}").data(using: .utf8)
        var correlationTokenPath = ""
        var correlationToken: String?
        
        if(withCorrelationToken){
            correlationToken = UUID().uuidString
            correlationTokenPath = "clientToken"
            payload = String("{\"\(correlationTokenPath)\":\"\(correlationToken!)\"}").data(using: .utf8)
        }
        
        let responsePaths: [ResponsePath] = [ResponsePath(topic: acceptedTopic, correlationTokenJsonPath: correlationTokenPath),
                                             ResponsePath(topic: rejectedTopic, correlationTokenJsonPath: correlationTokenPath)]
        
        testContext.responsePaths = responsePaths
        testContext.correlationToken = correlationToken
        
        return RequestResponseOperationOptions(subscriptionTopicFilters: [subscriptionTopicFilter], responsePaths:responsePaths, topic: publishTopic, payload: payload!, correlationToken:  correlationToken)
    }
    
    // create an update rr request
    func createRequestResponseUpdateOptions(testContext: MqttRRTestContext , shadowName : String = UUID().uuidString, thingName: String, withCorrelationToken: Bool = true) -> RequestResponseOperationOptions {
        let acceptedTopic = "$aws/things/\(thingName)/shadow/name/\(shadowName)/update/accepted"
        let rejectedTopic = "$aws/things/\(thingName)/shadow/name/\(shadowName)/update/rejected"
        let publishTopic = "$aws/things/\(thingName)/shadow/name/\(shadowName)/update"
        let subscriptionTopicFilters = [acceptedTopic, rejectedTopic]
        
        var correlationTokenPath = ""
        var correlationToken: String?
        
        let stateToken = UUID().uuidString
        let desiredState = "{\"magic\":\"\(stateToken)\"}"
        var payload = "{\"state\":{\"desired\":\(desiredState)}}".data(using: .utf8)
        
        if(withCorrelationToken){
            correlationToken = UUID().uuidString
            correlationTokenPath = "clientToken"
            payload = String("{\"\(correlationTokenPath)\":\"\(correlationToken!)\", \"state\":{\"desired\":\(desiredState)}}").data(using: .utf8)
        }
    
        let responsePaths: [ResponsePath] = [ResponsePath(topic: acceptedTopic, correlationTokenJsonPath: correlationTokenPath),
                                             ResponsePath(topic: rejectedTopic, correlationTokenJsonPath: correlationTokenPath)]
        
        testContext.responsePaths = responsePaths
        testContext.correlationToken = correlationToken
        
        return RequestResponseOperationOptions(subscriptionTopicFilters: subscriptionTopicFilters, responsePaths:responsePaths, topic: publishTopic, payload: payload!, correlationToken:  correlationToken)
    }
    
    
    // MARK: - request response client tests

    func testMqttRequestResponse_CreateDestroy() async throws {
        let testContext = MqttRRTestContext()
        let mqtt5Client = try createMqtt5Client(testContext: testContext)
        let _ = try MqttRequestResponseClient.newFromMqtt5Client(mqtt5Client: mqtt5Client)
    }
    
    func testMqttRequestResponse_GetNamedShadowSuccessRejected() async throws {
        let testContext = MqttRRTestContext()
        let rrClient = try await setupRequestResponseClient(testContext: testContext)
        let requestOptions = createRequestResponseGetOptions(testContext: testContext, thingName: "NoSuchThing")
        let response = try await rrClient.submitRequest(operationOptions: requestOptions);

        XCTAssertEqual(response.topic, testContext.responsePaths![1].topic)
        if let paylaodString = String(data: response.payload, encoding: .utf8){
            XCTAssertTrue(paylaodString.contains("No shadow exists with name"))
        }else{
            XCTFail("MqttRequestResponseResponse: Invalid Payload.")
        }

        // cleanup
        testContext.cleanup()
    }
    
    func testMqttRequestResponse_GetNamedShadowSuccessRejectedNoCorrelationToken() async throws {
        let testContext = MqttRRTestContext()
        let rrClient = try await setupRequestResponseClient(testContext: testContext)
        let requestOptions = createRequestResponseGetOptions(testContext: testContext, thingName: "NoSuchThing", withCorrelationToken: false)
        
        let response = try await rrClient.submitRequest(operationOptions: requestOptions);
        
        XCTAssertEqual(response.topic, testContext.responsePaths![1].topic)
        if let paylaodString = String(data: response.payload, encoding: .utf8){
            XCTAssertTrue(paylaodString.contains("No shadow exists with name"))
        }else{
            XCTFail("MqttRequestResponseResponse: Invalid Payload.")
        }
        testContext.cleanup()
    }
    
    func testMqttRequestResponse_UpdateNamedShadowSuccessAccepted() async throws{
        let testContext = MqttRRTestContext()
        let rrClient = try await setupRequestResponseClient(testContext: testContext)
        let requestOptions = createRequestResponseUpdateOptions(testContext: testContext , thingName: "NoSuchThing")
        
        let response = try await rrClient.submitRequest(operationOptions: requestOptions);

        XCTAssertEqual(response.topic, testContext.responsePaths![0].topic)
        if let paylaodString = String(data: response.payload, encoding: .utf8){
            XCTAssertTrue(paylaodString.lengthOfBytes(using: .utf8) > 0)
        }else{
            XCTFail("MqttRequestResponseResponse: Invalid Payload.")
        }
        testContext.cleanup()
    }
    
    func testMqttRequestResponse_UpdateNamedShadowSuccessAcceptedNoCorrelationToken() async throws{
        let testContext = MqttRRTestContext()
        let rrClient = try await setupRequestResponseClient(testContext: testContext)
        let requestOptions = createRequestResponseUpdateOptions(testContext: testContext , thingName: "NoSuchThing", withCorrelationToken: false)
        
        let response = try await rrClient.submitRequest(operationOptions: requestOptions);

        XCTAssertEqual(response.topic, testContext.responsePaths![0].topic)
        if let paylaodString = String(data: response.payload, encoding: .utf8){
            XCTAssertTrue(paylaodString.lengthOfBytes(using: .utf8) > 0)
        }else{
            XCTFail("MqttRequestResponseResponse: Invalid Payload.")
        }
        testContext.cleanup()
    }
    
    func testMqttRequestResponse_GetNamedShadowTimeout() async throws{
        let testContext = MqttRRTestContext()
        let rrClient = try await setupRequestResponseClient(testContext: testContext)
        let requestOptions = createRequestResponseGetOptions(testContext: testContext, thingName: "NoSuchThing", publishTopic: "wrong/publish/topic")
        var errorCaught = false
        
        do {
            let _ = try await rrClient.submitRequest(operationOptions: requestOptions);
        }
        catch CommonRunTimeError.crtError(let crtError) {
            XCTAssertEqual(crtError.code, Int32(AWS_ERROR_MQTT_REQUEST_RESPONSE_TIMEOUT.rawValue))
            errorCaught = true
        }
        
        XCTAssertTrue(errorCaught)
        // cleanup
        testContext.cleanup()
    }
    
    func testMqttRequestResponse_GetNamedShadowTimeoutNoCorrelationToken() async throws {
        let testContext = MqttRRTestContext()
        let rrClient = try await setupRequestResponseClient(testContext: testContext)
        let requestOptions = createRequestResponseGetOptions(testContext: testContext, thingName: "NoSuchThing", withCorrelationToken: false, publishTopic: "wrong/publish/topic")
        var errorCaught = false
        
        do {
            let _ = try await rrClient.submitRequest(operationOptions: requestOptions);
        }
        catch CommonRunTimeError.crtError(let crtError) {
            XCTAssertEqual(crtError.code, Int32(AWS_ERROR_MQTT_REQUEST_RESPONSE_TIMEOUT.rawValue))
            errorCaught = true
        }
        
        XCTAssertTrue(errorCaught)
        // cleanup
        testContext.cleanup()
    }

    func testMqttRequestResponse_ShadowUpdatedStreamOpenCloseSuccess() async throws {
        let testContext = MqttRRTestContext()
        let rrClient = try await setupRequestResponseClient(testContext: testContext)
        let streamingOperation = try rrClient.createStream(streamOptions: StreamingOperationOptions(topicFilter: "test/topic",
                                                                                                    subscriptionStatusCallback: testContext.onSubscriptionStatusUpdate))
        
        streamingOperation.open()
        
        await awaitExpectation([testContext.subscriptionStatusSuccessExpectation], 60)
    }

    func testMqttRequestResponse_ShadowUpdatedStreamClientClosed() async throws {
        let testContext = MqttRRTestContext()
        var rrClient : MqttRequestResponseClient? = try await setupRequestResponseClient(testContext: testContext)
        XCTAssertNotNil(rrClient)
        var streamingOperation : StreamingOperation? = try rrClient!.createStream(streamOptions: StreamingOperationOptions(topicFilter: "test/topic",
                                                                                                    subscriptionStatusCallback: testContext.onSubscriptionStatusUpdate))
        
        XCTAssertNotNil(streamingOperation)
        // open the operation successfully
        streamingOperation!.open()
        await awaitExpectation([testContext.subscriptionStatusSuccessExpectation], 60)
        
        // destory the request response client
        streamingOperation = nil

        rrClient = nil
        
//        await awaitExpectation([testContext.subscriptionStatusErrorExpectation], 60)
//        XCTAssertEqual(testContext.subscriptionStatusEvent?.event, SubscriptionStatusEventType.halted)
//        XCTAssertEqual(testContext.subscriptionStatusEvent?.error?.code,
//                       Int32(AWS_ERROR_MQTT_REQUEST_RESPONSE_CLIENT_SHUT_DOWN.rawValue))
//        // TODO: this should be removed. release operation before we exit the test
    }

    func MqttRequestResponse_ShadowUpdatedStreamIncomingPublishSuccess() throws {
        
    }
}
