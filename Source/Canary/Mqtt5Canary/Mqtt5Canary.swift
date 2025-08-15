//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import ArgumentParser
import AwsCommonRuntimeKit
import Foundation
import _Concurrency

let ONE_NANO_SECOND: UInt64 = 1_000_000_000
let SLEEP_OVERHEAD_NS: UInt64 = 2_000_000  // 2ms overhead
let UNSUBSCRIBED_TEST_TOPIC = "SwiftCanary/Unsubscribed/" + UUID().uuidString

typealias OnMqtt5CanaryTestFunction = (Mqtt5CanaryTestContext) -> Void

enum CanaryTestError: Error {
  case InvalidArgument
}

class Mqtt5CanaryTestContext: @unchecked Sendable {
  var mqtt5CanaryClients: [Mqtt5CanaryClient] = []
  var statistic: Mqtt5CanaryStatistic

  init() {
    statistic = Mqtt5CanaryStatistic()
  }

  /// Setup Test Context
  func appendCanaryClient(client: Mqtt5CanaryClient) {
    mqtt5CanaryClients.append(client)
  }

  func setClientConnection(index: Int, connected: Bool) {
    mqtt5CanaryClients[index].setConnected(connected: connected)
  }

  /// Client Operation Help Function
  func mqtt5CanaryRunOperation(_ operation: Mqtt5CanaryOperation, _ index: Int) async throws {
    switch operation {
    case Mqtt5CanaryOperation.START:
      try await mqtt5CanaryOperationStart(clientIndex: index)
    case Mqtt5CanaryOperation.STOP:
      try await mqtt5CanaryOperationStop(clientIndex: index)
    case Mqtt5CanaryOperation.SUBSCRIBE:
      try await mqtt5CanaryOperationSubscribe(clientIndex: index)
    case Mqtt5CanaryOperation.UNSUBSCRIBE:
      if (mqtt5CanaryClients[index].subscriptionCount > 0) {
        try await mqtt5CanaryOperationUnsubscribe(
          clientIndex: index, testTopic: mqtt5CanaryClients[index].getUnsubscribedTopic())
      } else {
        // If there is topic subscribed, fallthrough to UNSUBSSCRIBE_BAD operation
        fallthrough
      }
    case Mqtt5CanaryOperation.UNSUBSCRIBE_BAD:
      try await mqtt5CanaryOperationUnsubscribe(clientIndex: index)
    case Mqtt5CanaryOperation.PUBLISH_QOS0:
      try await mqtt5CanaryOperationPublish(clientIndex: index, qos: QoS.atMostOnce)
    case Mqtt5CanaryOperation.PUBLISH_QOS1:
      try await mqtt5CanaryOperationPublish(clientIndex: index, qos: QoS.atLeastOnce)
    case Mqtt5CanaryOperation.PUBLISH_TO_SUBSCRIBED_TOPIC_QOS0:
      try await mqtt5CanaryOperationPublish(
        clientIndex: index, topic: mqtt5CanaryClients[index].getSubscribedTopic(),
        qos: QoS.atMostOnce)
    case Mqtt5CanaryOperation.PUBLISH_TO_SUBSCRIBED_TOPIC_QOS1:
      try await mqtt5CanaryOperationPublish(
        clientIndex: index, topic: mqtt5CanaryClients[index].getSubscribedTopic(),
        qos: QoS.atLeastOnce)
    case Mqtt5CanaryOperation.PUBLISH_TO_SHARED_TOPIC_QOS0:
      try await mqtt5CanaryOperationPublish(
        clientIndex: index, topic: mqtt5CanaryClients[index].shared_topic, qos: QoS.atMostOnce)
    case Mqtt5CanaryOperation.PUBLISH_TO_SHARED_TOPIC_QOS1:
      try await mqtt5CanaryOperationPublish(
        clientIndex: index, topic: mqtt5CanaryClients[index].shared_topic, qos: QoS.atLeastOnce)

    case Mqtt5CanaryOperation.NULL:
      fallthrough
    case Mqtt5CanaryOperation.OPERATION_COUNT:
      throw CanaryTestError.InvalidArgument
    }

  }

  /// Client Operations
  func mqtt5CanaryOperationStart(clientIndex: Int) async throws {
    if !mqtt5CanaryClients[clientIndex].is_connected {
      await statistic.incrementTotalOperation()
      try mqtt5CanaryClients[clientIndex].client.start()
    }
  }

  func mqtt5CanaryOperationStop(clientIndex: Int) async throws {
    if mqtt5CanaryClients[clientIndex].is_connected {
      await statistic.incrementTotalOperation()
      try mqtt5CanaryClients[clientIndex].client.stop()
      // clean up the subscription count
      mqtt5CanaryClients[clientIndex].subscriptionCount = 0
    }
  }

  func mqtt5CanaryOperationSubscribe(clientIndex: Int) async throws {
    if !mqtt5CanaryClients[clientIndex].is_connected {
      return try await mqtt5CanaryOperationStart(clientIndex: clientIndex)
    }

    do {
      let canaryClient = mqtt5CanaryClients[clientIndex]
      let sub = Subscription(topicFilter: canaryClient.getNextSubTopic(), qos: QoS.atLeastOnce)
      var subscriptions = [sub]

      await self.statistic.incrementSubscribeAttempts()
      await self.statistic.incrementTotalOperation()

      // If this is the first subscription of the client, subscribe to the shared topic
      if (canaryClient.subscriptionCount == 1) {
        subscriptions.append(
          Subscription(topicFilter: canaryClient.shared_topic, qos: QoS.atLeastOnce))
      }

      let suback = try await canaryClient.client.subscribe(
        subscribePacket: SubscribePacket(subscriptions: subscriptions))

      if suback.reasonCodes[0] == SubackReasonCode.grantedQos1 {
        await self.statistic.incrementSubscribeSucceed()
      } else {
        await self.statistic.incrementSubscribeFailed()
      }
    } catch {
      await self.statistic.incrementSubscribeFailed()
    }
  }

  func mqtt5CanaryOperationUnsubscribe(
    clientIndex: Int, testTopic: String = UNSUBSCRIBED_TEST_TOPIC
  ) async throws {
    if !mqtt5CanaryClients[clientIndex].is_connected {
      return try await mqtt5CanaryOperationStart(clientIndex: clientIndex)
    }

    do {
      let canaryClient = mqtt5CanaryClients[clientIndex]
      let unsub = UnsubscribePacket(topicFilter: testTopic)

      await self.statistic.incrementUnsubscribeAttempts()
      await self.statistic.incrementTotalOperation()

      let unsubAck = try await canaryClient.client.unsubscribe(unsubscribePacket: unsub)

      if unsubAck.reasonCodes[0] == UnsubackReasonCode.success {
        await self.statistic.incrementUnsubscribeSucceed()
      } else {
        await self.statistic.incrementUnsubscribeFailed()
      }
    } catch {
      await self.statistic.incrementUnsubscribeFailed()
    }
  }

  func mqtt5CanaryOperationPublish(
    clientIndex: Int, topic: String = UNSUBSCRIBED_TEST_TOPIC, qos: QoS
  ) async throws {
    if !mqtt5CanaryClients[clientIndex].is_connected {
      return try await mqtt5CanaryOperationStart(clientIndex: clientIndex)
    }

    do {
      let canaryClient = mqtt5CanaryClients[clientIndex]
      let pub = PublishPacket(qos: qos, topic: topic)

      await self.statistic.incrementPublishAttempts()
      await self.statistic.incrementTotalOperation()
      let puback = try await canaryClient.client.publish(publishPacket: pub)

      if qos == QoS.atMostOnce || puback.puback?.reasonCode == PubackReasonCode.success
        || puback.puback?.reasonCode == PubackReasonCode.noMatchingSubscribers
      {
        await self.statistic.incrementPublishSucceed()
      } else {
        await self.statistic.incrementPublishFailed()
      }
    } catch {
      await self.statistic.incrementPublishFailed()
    }
  }

}

class Mqtt5CanaryClient {
  fileprivate let client: Mqtt5Client
  fileprivate let clientId: String
  fileprivate let shared_topic: String
  fileprivate var subscriptionCount: Int = 0
  fileprivate var is_connected: Bool = false

  init(client: Mqtt5Client, clientId: String, sharedTopic: String) {
    self.clientId = clientId
    self.client = client
    self.shared_topic = sharedTopic
  }

  func getNextSubTopic() -> String {
    self.subscriptionCount += 1
    return self.clientId + "_" + String(self.subscriptionCount);
  }

  func getSubscribedTopic() -> String {
    return self.clientId + "_" + String(self.subscriptionCount);
  }

  func getUnsubscribedTopic() -> String {
    let topic = self.clientId + "_" + String(self.subscriptionCount);
    if (self.subscriptionCount > 0) {
      self.subscriptionCount -= 1
    }
    return topic
  }

  func setConnected(connected: Bool) {
    self.is_connected = connected
  }

}

actor Mqtt5CanaryStatistic {
  var totalOperation: Int = 0

  var subscribeAttempt: Int = 0
  var subscribeSucceed: Int = 0
  var subscribeFailed: Int = 0

  var publishAttempt: Int = 0
  var publishSucceed: Int = 0
  var publishFailed: Int = 0

  var unsubAttempt: Int = 0
  var unsubSucceed: Int = 0
  var unsubFailed: Int = 0

  init() {
  }

  func incrementTotalOperation() {
    self.totalOperation += 1;
  }

  func incrementPublishAttempts() {
    self.publishAttempt += 1;
  }

  func incrementPublishSucceed() {
    self.publishSucceed += 1;
  }

  func incrementPublishFailed() {
    self.publishFailed += 1;
  }

  func incrementSubscribeAttempts() {
    self.subscribeAttempt += 1;
  }

  func incrementSubscribeSucceed() {
    self.subscribeSucceed += 1;
  }

  func incrementSubscribeFailed() {
    self.subscribeFailed += 1;
  }

  func incrementUnsubscribeAttempts() {
    self.unsubAttempt += 1;
  }

  func incrementUnsubscribeSucceed() {
    self.unsubSucceed += 1;
  }

  func incrementUnsubscribeFailed() {
    self.unsubFailed += 1;
  }

  func printStatistics(duration: TimeInterval) {
    let subscribeSuccessRate =
      subscribeAttempt > 0 ? Double(subscribeSucceed) / Double(subscribeAttempt) * 100 : 0
    let publishSuccessRate =
      publishAttempt > 0 ? Double(publishSucceed) / Double(publishAttempt) * 100 : 0
    let unsubscribeSuccessRate =
      unsubAttempt > 0 ? Double(unsubSucceed) / Double(unsubAttempt) * 100 : 0
    let totalTPS = duration > 0 ? Double(totalOperation) / duration : 0

    print("=== MQTT5 Canary Test Statistics ===")
    print("Test Duration: \(String(format: "%.2f", duration)) seconds")
    print("Total Operations: \(totalOperation)")
    print("Total TPS: \(String(format: "%.2f", totalTPS))")
    print(
      "Subscribe - Attempts: \(subscribeAttempt), Success: \(subscribeSucceed), Failed: \(subscribeFailed), Success Rate: \(String(format: "%.2f", subscribeSuccessRate))%"
    )
    print(
      "Publish - Attempts: \(publishAttempt), Success: \(publishSucceed), Failed: \(publishFailed), Success Rate: \(String(format: "%.2f", publishSuccessRate))%"
    )
    print(
      "Unsubscribe - Attempts: \(unsubAttempt), Success: \(unsubSucceed), Failed: \(unsubFailed), Success Rate: \(String(format: "%.2f", unsubscribeSuccessRate))%"
    )
  }

}

enum Mqtt5CanaryOperation: Int {
  case NULL = 0
  case START
  case STOP
  case SUBSCRIBE
  case UNSUBSCRIBE
  case UNSUBSCRIBE_BAD
  case PUBLISH_QOS0
  case PUBLISH_QOS1
  case PUBLISH_TO_SUBSCRIBED_TOPIC_QOS0
  case PUBLISH_TO_SUBSCRIBED_TOPIC_QOS1
  case PUBLISH_TO_SHARED_TOPIC_QOS0
  case PUBLISH_TO_SHARED_TOPIC_QOS1
  case OPERATION_COUNT
}

// This struct holds the canary options
// Adjustification of "@uncheck Sendable": The memebers in this struct will not be modified once setup.
struct Mqtt5CanaryTestOptions: @unchecked Sendable {
  // Client options
  let shared_topic: String
  var elg: EventLoopGroup
  var boostrap: ClientBootstrap
  var tlsctx: TLSContext? = nil
  // Test options
  let tpsSleepTime: UInt64
  var onWebsocketTransform: OnWebSocketHandshakeIntercept? = nil
  var operationDistribution: [Mqtt5CanaryOperation] = []

  init(testApp: Mqtt5Canary) throws {
    shared_topic = "shared_topic_" + UUID().uuidString
    self.tpsSleepTime = testApp.tps > 0 ? (UInt64(ONE_NANO_SECOND / testApp.tps)) : 0
    // Initialize elg first
    self.elg = try EventLoopGroup(threadCount: testApp.threads)
    let resolver = try HostResolver(
      eventLoopGroup: self.elg,
      maxHosts: 8,
      maxTTL: 30)
    self.boostrap = try ClientBootstrap(
      eventLoopGroup: self.elg,
      hostResolver: resolver)

    try self.setupClientOption(testApp: testApp)

    // Setup operation distribution
    Mqtt5CanaryOperationDistributionSetup(&self.operationDistribution)
  }

  mutating func setupClientOption(testApp: Mqtt5Canary) throws {
    if (testApp.useTls && self.tlsctx == nil) {
      guard let _cert = testApp.cert, let _key = testApp.key else {
        throw CanaryTestError.InvalidArgument
      }
      let tlsOptions = try TLSContextOptions.makeMTLS(
        certificatePath: _cert,
        privateKeyPath: _key
      )

      if let _caPath = testApp.caPath {
        try tlsOptions.overrideDefaultTrustStoreWithFile(caFile: _caPath)
      }
      self.tlsctx = try TLSContext(options: tlsOptions, mode: .client)
    }

    if (testApp.useWebsocket) {
      self.onWebsocketTransform = { request, complete in
        // Simply complete the request with success
        complete(request, 0)
      }
    }
  }
}

func Mqtt5CanaryOperationDistributionSetup(_ distributionDataSet: inout [Mqtt5CanaryOperation]) {
  let operationDistribution = [
    (Mqtt5CanaryOperation.STOP, 1),
    (Mqtt5CanaryOperation.SUBSCRIBE, 200),
    (Mqtt5CanaryOperation.UNSUBSCRIBE, 200),
    (Mqtt5CanaryOperation.UNSUBSCRIBE_BAD, 50),
    (Mqtt5CanaryOperation.PUBLISH_QOS0, 300),
    (Mqtt5CanaryOperation.PUBLISH_QOS1, 150),
    (Mqtt5CanaryOperation.PUBLISH_TO_SUBSCRIBED_TOPIC_QOS0, 100),
    (Mqtt5CanaryOperation.PUBLISH_TO_SUBSCRIBED_TOPIC_QOS1, 50),
    (Mqtt5CanaryOperation.PUBLISH_TO_SHARED_TOPIC_QOS0, 50),
    (Mqtt5CanaryOperation.PUBLISH_TO_SHARED_TOPIC_QOS1, 50),
  ]

  for distribution in operationDistribution {
    for _ in 0..<distribution.1 {
      distributionDataSet.append(distribution.0)
    }
  }

}

@Sendable func Mqtt5CanaryTestRunIteration(
  _ context: Mqtt5CanaryTestContext, _ options: Mqtt5CanaryTestOptions
) async throws -> Void {
  let operationIndex = Int.random(in: 0..<options.operationDistribution.count)
  let clientIndex = Int.random(in: 0..<context.mqtt5CanaryClients.count)
  try await context.mqtt5CanaryRunOperation(
    options.operationDistribution[operationIndex], clientIndex)
}

@main
struct Mqtt5Canary: AsyncParsableCommand {

  @Option(name: .long, help: "Hostname to connect")
  var endpoint: String = "localhost"

  @Option(name: .long, help: "Port to connect")
  var port: UInt32 = 1883

  @Option(name: .long, help: "Path to a CA certificate file.")
  var caPath: String? = nil

  @Option(
    name: .long,
    help: "Path to a PEM encoded certificate to use with mTLS. Required if useTls is True.")
  var cert: String? = nil

  @Option(
    name: .long,
    help: "Path to a PEM encoded private key that matches cert. Required if useTls is True.")
  var key: String? = nil

  @Option(name: .long, help: "Dumps logs to FILE instead of stderr")
  var logFile: String? = nil

  @Option(
    name: .long,
    help: "ERROR|INFO|DEBUG|TRACE: log level to configure.")
  var verbose: String = "ERROR"

  @Option(
    name: .long,
    help: "use mqtt-over-websockets rather than direct mqtt")
  var useWebsocket: Bool = false

  @Option(
    name: .long,
    help: "use tls with MQTT connection")
  var useTls: Bool = false

  @Option(
    name: .shortAndLong,
    help: "number of event loop group threads to use")
  var threads: UInt16 = 5

  @Option(
    name: .shortAndLong,
    help: "number of mqtt5 clients to use")
  var clients: Int = 10

  @Option(
    name: .long,
    help: "operations to run per second. No tps limits if set to 0. ")
  var tps: UInt64 = 60

  @Option(
    name: .shortAndLong,
    help: "seconds to run canary test")
  var seconds: Int = 3600

  init() {
  }

  func performOperation(context: Mqtt5CanaryTestContext) async {

  }

  mutating func createClient(
    context: Mqtt5CanaryTestContext, index: Int, testOptions: Mqtt5CanaryTestOptions
  ) async throws {
    let clientId = "Mqtt5CanaryTest-" + UUID().uuidString
    let connectionOption = MqttConnectOptions(clientId: clientId)
    let clientOption = MqttClientOptions(
      hostName: self.endpoint, port: self.port, bootstrap: testOptions.boostrap,
      tlsCtx: testOptions.tlsctx,
      onWebsocketTransform: testOptions.onWebsocketTransform,
      connectOptions: connectionOption,
      onLifecycleEventStoppedFn: { _ in
        context.setClientConnection(index: index, connected: false)
      },
      onLifecycleEventConnectionSuccessFn: { _ in
        context.setClientConnection(index: index, connected: true)
      },
      onLifecycleEventConnectionFailureFn: { _ in
        context.setClientConnection(index: index, connected: false)
      },
      onLifecycleEventDisconnectionFn: { _ in
        context.setClientConnection(index: index, connected: false)
      }
    )
    let client = try Mqtt5Client(clientOptions: clientOption)
    let canaryClient = Mqtt5CanaryClient(
      client: client, clientId: clientId, sharedTopic: testOptions.shared_topic)
    context.appendCanaryClient(client: canaryClient)
  }

  mutating func run() async throws {
    CommonRuntimeKit.initialize()
    // Enable logging
    let logLevel = LogLevel.fromString(string: self.verbose)
    if let logFile = self.logFile {
      print("Enable logging with trace file")
      try? Logger.initialize(target: .filePath(logFile), level: logLevel)
    } else {
      print("Enable logging with stdout")
      try? Logger.initialize(target: .standardOutput, level: logLevel)
    }

    // Setup test options
    let testOptions = try Mqtt5CanaryTestOptions(testApp: self)
    // Setup test clients
    let context: Mqtt5CanaryTestContext = Mqtt5CanaryTestContext()
    for index: Int in 0..<self.clients {
      try await createClient(context: context, index: index, testOptions: testOptions)
    }

    // Main Test iteration
    let startTime = Date()
    let endTime = startTime.addingTimeInterval(TimeInterval(self.seconds))

    while Date() < endTime {
      let iterationStartTime = Date()
      Task{
        try await Mqtt5CanaryTestRunIteration(context, testOptions)
      }

      // Task.sleep always sleeps longer than requested due to system overhead. For more precise timing...
      // we use a busy waiting...
      if testOptions.tpsSleepTime > SLEEP_OVERHEAD_NS {
        try await Task.sleep(nanoseconds: testOptions.tpsSleepTime - SLEEP_OVERHEAD_NS)
      }
      let targetTime = iterationStartTime.addingTimeInterval(
        TimeInterval(testOptions.tpsSleepTime / ONE_NANO_SECOND))
      while Date() < targetTime {
        // Busy-wait for precision sleep
      }
    }

    // Close and clean up the clients
    for index: Int in 0..<self.clients {
      try await context.mqtt5CanaryRunOperation(Mqtt5CanaryOperation.STOP, index)
    }

    // Print final statistics
    let actualDuration = Date().timeIntervalSince(startTime)
    await context.statistic.printStatistics(duration: actualDuration)

  }

}
