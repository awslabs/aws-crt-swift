//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
import Foundation
import AwsCMqtt
@testable import AwsCommonRuntimeKit

class Mqtt5RRClientTests: XCBaseTestCase {
    
    class MqttRRTestContext {
        var contextName: String

        // rr client context
        var responsePaths: [ResponsePath]?
        var correlationToken: String?
        var payload: Data?
        
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
            
            self.publishReceivedExpectation = XCTestExpectation(description: "Expect publish received.")
            self.publishTargetReachedExpectation = XCTestExpectation(description: "Expect publish target reached")
            self.connectionSuccessExpectation = XCTestExpectation(description: "Expect connection Success")
            self.connectionFailureExpectation = XCTestExpectation(description: "Expect connection Failure")
            self.disconnectionExpectation = XCTestExpectation(description: "Expect disconnect")
            self.stoppedExpecation = XCTestExpectation(description: "Expect stopped")
            
            
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
        let rrClient = try MqttRequestResponseClient.newFromMqtt5Client(mqtt5Client: mqtt5Client)

        // start the client
        try await startClient(client: mqtt5Client, testContext: testContext)
        return rrClient
    }
    
    // create a rr request
    func createRequestResponseOptions(testContext: MqttRRTestContext , shadowName : String = UUID().uuidString, thingName: String, withCorrelationToken: Bool = false) -> RequestResponseOperationOptions {
        let subscriptionTopicFilter = "$aws/things/\(thingName)/shadow/name/\(shadowName)/get/+"
        let acceptedTopic = "$aws/things/\(thingName)/shadow/name/\(shadowName)/get/accepted"
        let rejectedTopic = "$aws/things/\(thingName)/shadow/name/\(shadowName)/get/rejected"
        let publishTopic = "$aws/things/\(thingName)/shadow/name/\(shadowName)/get"
                
        var payload = String("{}").data(using: .utf8)
        var correlationToken: String?
        if(withCorrelationToken){
            correlationToken = UUID().uuidString
            payload = String("{\"clientToken\":\"\(correlationToken)\"}").data(using: .utf8)
        }
        
        let responsePaths: [ResponsePath] = [ResponsePath(topic: acceptedTopic, correlationTokenJsonPath: "clientToken"),
                                             ResponsePath(topic: rejectedTopic, correlationTokenJsonPath: "clientToken")]
        
        testContext.responsePaths = responsePaths
        testContext.correlationToken = correlationToken
        
        return RequestResponseOperationOptions(subscriptionTopicFilters: [subscriptionTopicFilter], responsePaths:responsePaths, topic: publishTopic, payload: payload!, correlationToken:  correlationToken)
    }
    
    
    // MARK: - request response tests

    func testMqttRequestResponse_CreateDestroy() async throws {
        let testContext = MqttRRTestContext()
        let mqtt5Client = try createMqtt5Client(testContext: testContext)
        let _ = try MqttRequestResponseClient.newFromMqtt5Client(mqtt5Client: mqtt5Client)
    }
    
    func testMqttRequestResponse_GetNamedShadowSuccessRejected() async throws {
        var testContext = MqttRRTestContext()
        let rrClient = try await setupRequestResponseClient(testContext: testContext)
        let requestOptions = createRequestResponseOptions(testContext: testContext, thingName: "NoSuchThing")
        let response = try await rrClient.submitRequest(operationOptions: requestOptions);

        XCTAssertNil(response.error)
        XCTAssertEqual(response.topic, testContext.responsePaths![1].topic)
        if let paylaodString = String(data: response.payload, encoding: .utf8){
            XCTAssertTrue(paylaodString.contains("No shadow exists with name"))
        }else{
            XCTFail("MqttRequestResponseResponse: Invalid Payload.")
        }
    }
    
    func MqttRequestResponse_GetNamedShadowSuccessRejectedNoCorrelationToken() async throws {
        var testContext = MqttRRTestContext()
        let rrClient = try await setupRequestResponseClient(testContext: testContext)
        let requestOptions = createRequestResponseOptions(testContext: testContext, thingName: "NoSuchThing", withCorrelationToken: false)
        
        let response = try await rrClient.submitRequest(operationOptions: requestOptions);

        XCTAssertNil(response.error)
        XCTAssertEqual(response.topic, testContext.responsePaths![1].topic)
        if let paylaodString = String(data: response.payload, encoding: .utf8){
            XCTAssertTrue(paylaodString.contains("No shadow exists with name"))
        }else{
            XCTFail("MqttRequestResponseResponse: Invalid Payload.")
        }
    }
    
    func MqttRequestResponse_UpdateNamedShadowSuccessAccepted() async throws{
        var testContext = MqttRRTestContext()
        let rrClient = try await setupRequestResponseClient(testContext: testContext)
        let requestOptions = createRequestResponseOptions(testContext: testContext, thingName: "NoSuchThing")
        
        let response = try await rrClient.submitRequest(operationOptions: requestOptions);

        XCTAssertNil(response.error)
        XCTAssertEqual(response.topic, testContext.responsePaths![0].topic)
        if let paylaodString = String(data: response.payload, encoding: .utf8){
            XCTAssertTrue(paylaodString.contains("No shadow exists with name"))
        }else{
            XCTFail("MqttRequestResponseResponse: Invalid Payload.")
        }
    }
    
    func MqttRequestResponse_UpdateNamedShadowSuccessAcceptedNoCorrelationToken() throws{
        
    }
    
    func MqttRequestResponse_GetNamedShadowTimeout() throws{
        
    }
    
    func MqttRequestResponse_GetNamedShadowTimeoutNoCorrelationToken() throws {
        
    }
    
    func MqttRequestResponse_GetNamedShadowFailureOnClose() throws{
        
    }
    
    func MqttRequestResponse_GetNamedShadowFailureOnCloseNoCorrelationToken() throws {
        
    }
    
    func MqttRequestResponse_ShadowUpdatedStreamOpenCloseSuccess() throws {
        
    }
    
    func MqttRequestResponse_ShadowUpdatedStreamClientClosed() throws {
        
    }
    
    func MqttRequestResponse_ShadowUpdatedStreamIncomingPublishSuccess() throws {
        
    }
}
