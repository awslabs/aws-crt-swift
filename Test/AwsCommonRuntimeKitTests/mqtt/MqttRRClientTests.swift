//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
import Foundation
import AwsCMqtt
@testable import AwsCommonRuntimeKit

class Mqtt5RRClientTests: XCBaseTestCase {

  final class MqttRRTestContext: @unchecked Sendable {
    let contextName: String

    var responsePaths: [ResponsePath]?
    var correlationToken: String?
    var payload: Data?

    // protocol client context
    var publishReceivedExpectation: XCTestExpectation
    var publishTargetReachedExpectation: XCTestExpectation
    var connectionSuccessExpectation: XCTestExpectation
    var connectionFailureExpectation: XCTestExpectation
    var disconnectionExpectation: XCTestExpectation
    var stoppedExpectation: XCTestExpectation

    let onPublishReceived: OnPublishReceived?
    let onLifecycleEventStopped: OnLifecycleEventStopped?
    let onLifecycleEventAttemptingConnect: OnLifecycleEventAttemptingConnect?
    let onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess?
    let onLifecycleEventConnectionFailure: OnLifecycleEventConnectionFailure?
    let onLifecycleEventDisconnection: OnLifecycleEventDisconnection?

    init(contextName: String = "MqttClient") {
      self.contextName = contextName

      self.publishReceivedExpectation = XCTestExpectation(description: "Expect publish received.")
      self.publishTargetReachedExpectation = XCTestExpectation(
        description: "Expect publish target reached")
      self.connectionSuccessExpectation = XCTestExpectation(
        description: "Expect connection Success")
      self.connectionFailureExpectation = XCTestExpectation(
        description: "Expect connection Failure")
      self.disconnectionExpectation = XCTestExpectation(description: "Expect disconnect")
      self.stoppedExpectation = XCTestExpectation(description: "Expect stopped")

      self.onPublishReceived = {
        [publishReceivedExpectation = self.publishReceivedExpectation] publishData in
        if let payloadString = publishData.publishPacket.payloadAsString() {
          print(
            contextName
              + " MqttRRClientTests: onPublishReceived. Topic:\'\(publishData.publishPacket.topic)\' QoS:\(publishData.publishPacket.qos) payload:\'\(payloadString)\'"
          )
        } else {
          print(
            contextName
              + " MqttRRClientTests: onPublishReceived. Topic:\'\(publishData.publishPacket.topic)\' QoS:\(publishData.publishPacket.qos)"
          )
        }
        publishReceivedExpectation.fulfill()
      }

      self.onLifecycleEventStopped = { [stoppedExpectation = self.stoppedExpectation] _ in
        print(contextName + " MqttRRClientTests: onLifecycleEventStopped")
        stoppedExpectation.fulfill()
      }

      self.onLifecycleEventAttemptingConnect = { _ in
        print(contextName + " MqttRRClientTests: onLifecycleEventAttemptingConnect")
      }

      self.onLifecycleEventConnectionSuccess = {
        [connectionSuccessExpectation = self.connectionSuccessExpectation] successData in
        print(contextName + " MqttRRClientTests: onLifecycleEventConnectionSuccess")
        connectionSuccessExpectation.fulfill()
      }

      self.onLifecycleEventConnectionFailure = {
        [connectionFailureExpectation = self.connectionFailureExpectation] failureData in
        print(contextName + " MqttRRClientTests: onLifecycleEventConnectionFailure")
        connectionFailureExpectation.fulfill()
      }
      self.onLifecycleEventDisconnection = {
        [disconnectionExpectation = self.disconnectionExpectation] disconnectionData in
        print(contextName + " MqttRRClientTests: onLifecycleEventDisconnection")
        disconnectionExpectation.fulfill()
      }
    }

    // release the context before exit the test case
    func cleanup() {
      self.responsePaths = nil
    }
  }

  func createMqtt5Client(testContext: MqttRRTestContext) throws -> Mqtt5Client {
    try skipIfPlatformDoesntSupportTLS()
    let inputHost = try getEnvironmentVarOrSkipTest(
      environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")
    let inputCert = try getEnvironmentVarOrSkipTest(
      environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_CERT")
    let inputKey = try getEnvironmentVarOrSkipTest(
      environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_KEY")

    let elg = try EventLoopGroup()
    let resolver = try HostResolver(
      eventLoopGroup: elg,
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
  func startClient(client: Mqtt5Client, testContext: MqttRRTestContext) async throws {
    try client.start()
    await awaitExpectation([testContext.connectionSuccessExpectation], 5)

  }

  // stop client and check for discconnection and stopped lifecycle events
  func stopClient(
    client: Mqtt5Client, testContext: MqttRRTestContext, disconnectPacket: DisconnectPacket? = nil
  ) async throws -> Void {
    try client.stop(disconnectPacket: disconnectPacket)
    return await awaitExpectation([testContext.stoppedExpectation], 5)
  }

  // setup rr client
  func setupRequestResponseClient(
    testContext: MqttRRTestContext, options: MqttRequestResponseClientOptions? = nil
  ) async throws -> MqttRequestResponseClient {
    let mqtt5Client = try createMqtt5Client(testContext: testContext)
    let rrClient = try MqttRequestResponseClient(
      mqtt5Client: mqtt5Client,
      options: options
        ?? MqttRequestResponseClientOptions(
          maxRequestResponseSubscription: 3, maxStreamingSubscription: 2, operationTimeout: 60))

    // start the client
    try await startClient(client: mqtt5Client, testContext: testContext)
    return rrClient
  }

  // create a get rr request
  func createRequestResponseGetOptions(
    testContext: MqttRRTestContext, shadowName: String = UUID().uuidString, thingName: String,
    withCorrelationToken: Bool = true, publishTopic: String? = nil
  ) -> RequestResponseOperationOptions {
    let subscriptionTopicFilter = "$aws/things/\(thingName)/shadow/name/\(shadowName)/get/+"
    let acceptedTopic = "$aws/things/\(thingName)/shadow/name/\(shadowName)/get/accepted"
    let rejectedTopic = "$aws/things/\(thingName)/shadow/name/\(shadowName)/get/rejected"
    let publishTopic = publishTopic ?? "$aws/things/\(thingName)/shadow/name/\(shadowName)/get"

    var payload = String("{}").data(using: .utf8)
    var correlationTokenPath = ""
    var correlationToken: String?

    if (withCorrelationToken) {
      correlationToken = UUID().uuidString
      correlationTokenPath = "clientToken"
      payload = String("{\"\(correlationTokenPath)\":\"\(correlationToken!)\"}").data(using: .utf8)
    }

    let responsePaths: [ResponsePath] = [
      ResponsePath(topic: acceptedTopic, correlationTokenJsonPath: correlationTokenPath),
      ResponsePath(topic: rejectedTopic, correlationTokenJsonPath: correlationTokenPath),
    ]

    testContext.responsePaths = responsePaths
    testContext.correlationToken = correlationToken

    return RequestResponseOperationOptions(
      subscriptionTopicFilters: [subscriptionTopicFilter], responsePaths: responsePaths,
      topic: publishTopic, payload: payload!, correlationToken: correlationToken)
  }

  // create an update rr request
  func createRequestResponseUpdateOptions(
    testContext: MqttRRTestContext, shadowName: String = UUID().uuidString, thingName: String,
    withCorrelationToken: Bool = true
  ) -> RequestResponseOperationOptions {
    let acceptedTopic = "$aws/things/\(thingName)/shadow/name/\(shadowName)/update/accepted"
    let rejectedTopic = "$aws/things/\(thingName)/shadow/name/\(shadowName)/update/rejected"
    let publishTopic = "$aws/things/\(thingName)/shadow/name/\(shadowName)/update"
    let subscriptionTopicFilters = [acceptedTopic, rejectedTopic]

    var correlationTokenPath = ""
    var correlationToken: String?

    let stateToken = UUID().uuidString
    let desiredState = "{\"magic\":\"\(stateToken)\"}"
    var payload = "{\"state\":{\"desired\":\(desiredState)}}".data(using: .utf8)

    if (withCorrelationToken) {
      correlationToken = UUID().uuidString
      correlationTokenPath = "clientToken"
      payload = String(
        "{\"\(correlationTokenPath)\":\"\(correlationToken!)\", \"state\":{\"desired\":\(desiredState)}}"
      ).data(using: .utf8)
    }

    let responsePaths: [ResponsePath] = [
      ResponsePath(topic: acceptedTopic, correlationTokenJsonPath: correlationTokenPath),
      ResponsePath(topic: rejectedTopic, correlationTokenJsonPath: correlationTokenPath),
    ]

    testContext.responsePaths = responsePaths
    testContext.correlationToken = correlationToken

    return RequestResponseOperationOptions(
      subscriptionTopicFilters: subscriptionTopicFilters, responsePaths: responsePaths,
      topic: publishTopic, payload: payload!, correlationToken: correlationToken)
  }

  // MARK: - request response client tests

  func testMqttRequestResponse_CreateDestroy() async throws {
    let testContext = MqttRRTestContext()
    let client = try createMqtt5Client(testContext: testContext)
    let _ = try MqttRequestResponseClient(
      mqtt5Client: client,
      options: MqttRequestResponseClientOptions(
        maxRequestResponseSubscription: 3, maxStreamingSubscription: 2, operationTimeout: 60))
  }

  func testMqttRequestResponse_GetNamedShadowSuccessRejected() async throws {
    let testContext = MqttRRTestContext()
    let rrClient = try await setupRequestResponseClient(testContext: testContext)
    let requestOptions = createRequestResponseGetOptions(
      testContext: testContext, thingName: "NoSuchThing")
    let response = try await rrClient.submitRequest(operationOptions: requestOptions);

    XCTAssertEqual(response.topic, testContext.responsePaths![1].topic)
    if let paylaodString = String(data: response.payload, encoding: .utf8) {
      XCTAssertTrue(paylaodString.contains("No shadow exists with name"))
    } else {
      XCTFail("MqttRequestResponse: Invalid Payload.")
    }

    // cleanup
    testContext.cleanup()
  }

  func testMqttRequestResponse_GetNamedShadowSuccessRejectedNoCorrelationToken() async throws {
    let testContext = MqttRRTestContext()
    let rrClient = try await setupRequestResponseClient(testContext: testContext)
    let requestOptions = createRequestResponseGetOptions(
      testContext: testContext, thingName: "NoSuchThing", withCorrelationToken: false)

    let response = try await rrClient.submitRequest(operationOptions: requestOptions);

    XCTAssertEqual(response.topic, testContext.responsePaths![1].topic)
    if let paylaodString = String(data: response.payload, encoding: .utf8) {
      XCTAssertTrue(paylaodString.contains("No shadow exists with name"))
    } else {
      XCTFail("MqttRequestResponse: Invalid Payload.")
    }
    testContext.cleanup()
  }

  func testMqttRequestResponse_UpdateNamedShadowSuccessAccepted() async throws {
    let testContext = MqttRRTestContext()
    let rrClient = try await setupRequestResponseClient(testContext: testContext)
    let requestOptions = createRequestResponseUpdateOptions(
      testContext: testContext, thingName: "NoSuchThing")

    let response = try await rrClient.submitRequest(operationOptions: requestOptions);

    XCTAssertEqual(response.topic, testContext.responsePaths![0].topic)
    if let paylaodString = String(data: response.payload, encoding: .utf8) {
      XCTAssertTrue(paylaodString.lengthOfBytes(using: .utf8) > 0)
    } else {
      XCTFail("MqttRequestResponse: Invalid Payload.")
    }
    testContext.cleanup()
  }

  func testMqttRequestResponse_UpdateNamedShadowSuccessAcceptedNoCorrelationToken() async throws {
    let testContext = MqttRRTestContext()
    let rrClient = try await setupRequestResponseClient(testContext: testContext)
    let requestOptions = createRequestResponseUpdateOptions(
      testContext: testContext, thingName: "NoSuchThing", withCorrelationToken: false)

    let response = try await rrClient.submitRequest(operationOptions: requestOptions);

    XCTAssertEqual(response.topic, testContext.responsePaths![0].topic)
    if let paylaodString = String(data: response.payload, encoding: .utf8) {
      XCTAssertTrue(paylaodString.lengthOfBytes(using: .utf8) > 0)
    } else {
      XCTFail("MqttRequestResponse: Invalid Payload.")
    }
    testContext.cleanup()
  }

  func testMqttRequestResponse_GetNamedShadowTimeout() async throws {
    let testContext = MqttRRTestContext()
    let rrClient = try await setupRequestResponseClient(
      testContext: testContext,
      options: MqttRequestResponseClientOptions(
        maxRequestResponseSubscription: 3, maxStreamingSubscription: 2, operationTimeout: 10))
    let requestOptions = createRequestResponseGetOptions(
      testContext: testContext, thingName: "NoSuchThing", publishTopic: "wrong/publish/topic")
    var errorCaught = false

    do {
      let _ = try await rrClient.submitRequest(operationOptions: requestOptions);
    } catch CommonRunTimeError.crtError(let crtError) {
      XCTAssertEqual(crtError.code, Int32(AWS_ERROR_MQTT_REQUEST_RESPONSE_TIMEOUT.rawValue))
      errorCaught = true
    }

    XCTAssertTrue(errorCaught)
    // cleanup
    testContext.cleanup()
  }

  func testMqttRequestResponse_GetNamedShadowTimeoutNoCorrelationToken() async throws {
    let testContext = MqttRRTestContext()
    let rrClient = try await setupRequestResponseClient(
      testContext: testContext,
      options: MqttRequestResponseClientOptions(
        maxRequestResponseSubscription: 3, maxStreamingSubscription: 2, operationTimeout: 10))
    let requestOptions = createRequestResponseGetOptions(
      testContext: testContext, thingName: "NoSuchThing", withCorrelationToken: false,
      publishTopic: "wrong/publish/topic")
    var errorCaught = false

    do {
      let _ = try await rrClient.submitRequest(operationOptions: requestOptions);
    } catch CommonRunTimeError.crtError(let crtError) {
      XCTAssertEqual(crtError.code, Int32(AWS_ERROR_MQTT_REQUEST_RESPONSE_TIMEOUT.rawValue))
      errorCaught = true
    }

    XCTAssertTrue(errorCaught)
    // cleanup
    testContext.cleanup()
  }

  func MqttRequestResponse_ShadowUpdatedStreamOpenCloseSuccess() throws {

  }

  func MqttRequestResponse_ShadowUpdatedStreamClientClosed() throws {

  }

  func MqttRequestResponse_ShadowUpdatedStreamIncomingPublishSuccess() throws {

  }
}
