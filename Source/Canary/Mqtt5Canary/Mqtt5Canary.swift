//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import ArgumentParser
import AwsCommonRuntimeKit
import Foundation
import _Concurrency

let ONE_NANO_SECOND: Double = 1_000_000_000
let UNSUBSCRIBED_TEST_TOPIC = "SwiftCanary/Unsubscribed/" + UUID().uuidString

typealias OnMqtt5CanaryTestFunction = (Mqtt5CanaryTestContext) -> Void

enum CanaryTestError: Error {
  case InvalidArgument
  case InvalidOperation
  case ClientNotFound  // Could not find client using the client id/index
  case ClientIsInvalid  // Internal Mqtt5 client is invalid, the client might be destroyed
}

actor Mqtt5CanaryTestContext {
  var mqtt5CanaryClients: [String: Mqtt5CanaryClient] = [:]
  var statistic: Mqtt5CanaryStatistic

  init() {
    statistic = Mqtt5CanaryStatistic()
  }

  /// Setup Test Context
  func appendCanaryClient(clientId: String, client: Mqtt5CanaryClient) {
    mqtt5CanaryClients[clientId] = client
  }

  func setClientConnection(clientId: String, connected: Bool) async throws {
    guard let client = mqtt5CanaryClients[clientId] else {
      throw CanaryTestError.ClientNotFound
    }
    await client.setConnected(connected: connected)
  }

  func getCanaryClient(_ index: Int) throws -> Mqtt5CanaryClient {
    let index = mqtt5CanaryClients.index(mqtt5CanaryClients.startIndex, offsetBy: index)
    let key = mqtt5CanaryClients.keys[index]
    guard let result = mqtt5CanaryClients[key] else {
      throw CanaryTestError.ClientNotFound
    }
    return result
  }

  func getCanaryClient(_ clientId: String) throws -> Mqtt5CanaryClient {
    guard let result = mqtt5CanaryClients[clientId] else {
      throw CanaryTestError.ClientNotFound
    }
    return result
  }

  func createClient(
    testOptions: Mqtt5CanaryTestOptions
  ) async throws {
    let clientId = "Mqtt5CanaryTest-" + UUID().uuidString
    let connectionOption = MqttConnectOptions(clientId: clientId)
    let clientOption = MqttClientOptions(
      hostName: testOptions.endpoint, port: testOptions.port, bootstrap: testOptions.boostrap,
      tlsCtx: testOptions.tlsctx,
      onWebsocketTransform: testOptions.onWebsocketTransform,
      connectOptions: connectionOption,
      onLifecycleEventStoppedFn: { _ in
        Task {
          try await self.setClientConnection(clientId: clientId, connected: false)
        }
      },
      onLifecycleEventConnectionSuccessFn: { _ in
        Task {
          try await self.setClientConnection(clientId: clientId, connected: true)
        }
      },
      onLifecycleEventConnectionFailureFn: { _ in
        Task {
          try await self.setClientConnection(clientId: clientId, connected: false)
        }
      },
      onLifecycleEventDisconnectionFn: { _ in
        Task {
          try await self.setClientConnection(clientId: clientId, connected: false)
        }
      }
    )
    let client = try Mqtt5Client(clientOptions: clientOption)
    let canaryClient = Mqtt5CanaryClient(
      client: client, clientId: clientId, sharedTopic: testOptions.shared_topic)
    appendCanaryClient(clientId: clientId, client: canaryClient)
  }

  /// Client Operation Help Function
  func mqtt5CanaryRunOperation(
    _ operation: Mqtt5CanaryOperation, _ index: Int, _ options: Mqtt5CanaryTestOptions
  ) async throws {
    switch operation {
    case Mqtt5CanaryOperation.STOP:
      try await mqtt5CanaryOperationStop(clientIndex: index)
    case Mqtt5CanaryOperation.SUBSCRIBE:
      try await mqtt5CanaryOperationSubscribe(clientIndex: index)
    case Mqtt5CanaryOperation.UNSUBSCRIBE:
      try await mqtt5CanaryOperationUnsubscribe(clientIndex: index)
    case Mqtt5CanaryOperation.UNSUBSCRIBE_BAD:
      try await mqtt5CanaryOperationUnsubscribeBad(clientIndex: index)
    case Mqtt5CanaryOperation.PUBLISH_QOS0:
      try await mqtt5CanaryOperationPublishUnsubscribed(clientIndex: index, qos: QoS.atMostOnce)
    case Mqtt5CanaryOperation.PUBLISH_QOS1:
      try await mqtt5CanaryOperationPublishUnsubscribed(clientIndex: index, qos: QoS.atLeastOnce)
    case Mqtt5CanaryOperation.PUBLISH_TO_SUBSCRIBED_TOPIC_QOS0:
      try await mqtt5CanaryOperationPublish(
        clientIndex: index, qos: QoS.atMostOnce)
    case Mqtt5CanaryOperation.PUBLISH_TO_SUBSCRIBED_TOPIC_QOS1:
      try await mqtt5CanaryOperationPublish(
        clientIndex: index, qos: QoS.atLeastOnce)
    case Mqtt5CanaryOperation.PUBLISH_TO_SHARED_TOPIC_QOS0:
      try await mqtt5CanaryOperationPublishShared(
        clientIndex: index, qos: QoS.atMostOnce)
    case Mqtt5CanaryOperation.PUBLISH_TO_SHARED_TOPIC_QOS1:
      try await mqtt5CanaryOperationPublishShared(
        clientIndex: index, qos: QoS.atLeastOnce)
    case Mqtt5CanaryOperation.DESTROY_AND_CREATE:
      try await mqtt5CanaryOperationDestroyAndCreate(clientIndex: index, option: options)
    case Mqtt5CanaryOperation.NULL:
      fallthrough
    case Mqtt5CanaryOperation.OPERATION_COUNT:
      throw CanaryTestError.InvalidOperation
    }

  }

  /// Client Operations
  func mqtt5CanaryOperationStart(clientIndex: Int) async throws {
    let canaryClient = try getCanaryClient(clientIndex)
    if await canaryClient.getConnected() == false {
      await statistic.incrementTotalOperation()
      if let _client = await canaryClient.client {
        // Client already exists, just start it
        try _client.start()
      } else {
        // Client does not exist, create a new one
        throw CanaryTestError.ClientIsInvalid
      }

    }
  }

  func mqtt5CanaryOperationStart(canaryClient: Mqtt5CanaryClient) async throws {
    if await !canaryClient.getConnected() {
      await statistic.incrementTotalOperation()
      if let _client = await canaryClient.client {
        // Client already exists, just start it
        try _client.start()
      } else {
        // Client does not exist, create a new one
        throw CanaryTestError.ClientIsInvalid
      }
    }
  }

  func mqtt5CanaryOperationStop(clientIndex: Int) async throws {
    let canaryClient = try getCanaryClient(clientIndex)
    if await !canaryClient.getConnected() {
      await statistic.incrementTotalOperation()
      if let _client = await canaryClient.client {
        try _client.stop()
      } else {
        throw CanaryTestError.ClientIsInvalid
      }
    }
  }

  func mqtt5CanaryOperationSubscribe(clientIndex: Int) async throws {
    let canaryClient = try getCanaryClient(clientIndex)
    if await !canaryClient.getConnected() {
      return try await mqtt5CanaryOperationStart(clientIndex: clientIndex)
    }

    let sub = Subscription(
      topicFilter: await canaryClient.getNextSubTopic(), qos: QoS.atLeastOnce)
    var subscriptions = [sub]

    // If this is the first subscription of the client, subscribe to the shared topic
    if (await canaryClient.subscriptionCount == 1) {
      subscriptions.append(
        Subscription(topicFilter: canaryClient.shared_topic, qos: QoS.atLeastOnce))
    }

    if let _client = await canaryClient.client {
      do {
        let suback = try await _client.subscribe(
          subscribePacket: SubscribePacket(subscriptions: subscriptions))

        await self.statistic.incrementSubscribeAttempts()
        await self.statistic.incrementTotalOperation()

        if suback.reasonCodes[0] == SubackReasonCode.grantedQos1 {
          await self.statistic.incrementSubscribeSucceed()
        } else {
          await self.statistic.incrementSubscribeFailed()
        }
      } catch {
        await self.statistic.incrementSubscribeFailed()
      }
    } else {
      throw CanaryTestError.ClientIsInvalid
    }
  }

  func mqtt5CanaryOperationUnsubscribe(clientIndex: Int) async throws {
    let canaryClient = try getCanaryClient(clientIndex)
    try await mqtt5CanaryOperationUnsubscribe(
      canaryClient: canaryClient, testTopic: await canaryClient.getUnsubscribedTopic())
  }

  func mqtt5CanaryOperationUnsubscribeBad(clientIndex: Int) async throws {
    let canaryClient = try getCanaryClient(clientIndex)
    try await mqtt5CanaryOperationUnsubscribe(canaryClient: canaryClient)
  }

  func mqtt5CanaryOperationUnsubscribe(
    canaryClient: Mqtt5CanaryClient, testTopic: String = UNSUBSCRIBED_TEST_TOPIC
  ) async throws {
    if await !canaryClient.getConnected() {
      return try await mqtt5CanaryOperationStart(canaryClient: canaryClient)
    }

    let unsub = UnsubscribePacket(topicFilter: testTopic)

    if let _client = await canaryClient.client {
      do {
        let unsubAck = try await _client.unsubscribe(unsubscribePacket: unsub)
        await self.statistic.incrementUnsubscribeAttempts()
        await self.statistic.incrementTotalOperation()

        if unsubAck.reasonCodes[0] == UnsubackReasonCode.success {
          await self.statistic.incrementUnsubscribeSucceed()
        } else {
          await self.statistic.incrementUnsubscribeFailed()
        }
      } catch {
        await self.statistic.incrementUnsubscribeFailed()
      }
    } else {
      throw CanaryTestError.ClientIsInvalid
    }
  }

  func mqtt5CanaryOperationPublish(clientIndex: Int, qos: QoS) async throws {
    let canaryClient = try getCanaryClient(clientIndex)
    try await mqtt5CanaryOperationPublish(
      canaryClient: canaryClient, topic: await canaryClient.getSubscribedTopic(), qos: qos)
  }

  func mqtt5CanaryOperationPublishUnsubscribed(clientIndex: Int, qos: QoS) async throws {
    let canaryClient = try getCanaryClient(clientIndex)
    try await mqtt5CanaryOperationPublish(canaryClient: canaryClient, qos: qos)
  }

  func mqtt5CanaryOperationPublishShared(clientIndex: Int, qos: QoS) async throws {
    let canaryClient = try getCanaryClient(clientIndex)
    try await mqtt5CanaryOperationPublish(
      canaryClient: canaryClient, topic: canaryClient.shared_topic, qos: qos)
  }

  func mqtt5CanaryOperationPublish(
    canaryClient: Mqtt5CanaryClient, topic: String = UNSUBSCRIBED_TEST_TOPIC, qos: QoS
  ) async throws {
    if await !canaryClient.getConnected() {
      return try await mqtt5CanaryOperationStart(canaryClient: canaryClient)
    }
    let pub = PublishPacket(qos: qos, topic: topic)

    if let _client = await canaryClient.client {
      do {
        let puback = try await _client.publish(publishPacket: pub)
        await self.statistic.incrementPublishAttempts()
        await self.statistic.incrementTotalOperation()

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
    } else {
      throw CanaryTestError.ClientIsInvalid
    }
  }

  func mqtt5CanaryOperationCreation(option: Mqtt5CanaryTestOptions) async throws {
    if mqtt5CanaryClients.count < option.clientCount {
      try await createClient(testOptions: option)
    }
  }

  func mqtt5CanaryOperationDestroyAndCreate(clientIndex: Int, option: Mqtt5CanaryTestOptions)
    async throws
  {
    // If there is one client left
    if mqtt5CanaryClients.count > 1 {
      let canaryClient = try getCanaryClient(clientIndex)
      if let _client = await canaryClient.client {
        try _client.stop()
      } else {
        throw CanaryTestError.ClientIsInvalid
      }
      await statistic.incrementTotalOperation()
      await canaryClient.resetClient()
      mqtt5CanaryClients.remove(
        at: mqtt5CanaryClients.index(mqtt5CanaryClients.startIndex, offsetBy: clientIndex))
      try await mqtt5CanaryOperationCreation(option: option)
    }
  }

}

actor Mqtt5CanaryClient {
  fileprivate var client: Mqtt5Client?
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
    return self.clientId + "_" + String(self.subscriptionCount)
  }

  func getSubscribedTopic() -> String {
    return self.clientId + "_" + String(self.subscriptionCount)
  }

  func getUnsubscribedTopic() -> String {
    let topic = self.clientId + "_" + String(self.subscriptionCount)
    if (self.subscriptionCount > 0) {
      self.subscriptionCount -= 1
    }
    return topic
  }

  func setConnected(connected: Bool) {
    self.is_connected = connected
  }

  func getConnected() -> Bool {
    return self.is_connected
  }

  func resetClient() {
    self.client = nil
    self.subscriptionCount = 0
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
  case DESTROY_AND_CREATE
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
// Justification of "@unchecked Sendable": The members in this struct will not be modified once setup.
struct Mqtt5CanaryTestOptions: @unchecked Sendable {
  // Client options
  let shared_topic: String
  let endpoint: String
  let port: UInt32
  let clientCount: Int
  var elg: EventLoopGroup
  var boostrap: ClientBootstrap
  var tlsctx: TLSContext? = nil
  // Test options
  let tpsSleepTime: UInt32
  var onWebsocketTransform: OnWebSocketHandshakeIntercept? = nil
  var operationDistribution: [Mqtt5CanaryOperation] = []

  init(testApp: Mqtt5Canary) throws {
    shared_topic = "shared_topic_" + UUID().uuidString
    self.endpoint = testApp.endpoint
    self.port = testApp.port
    self.tpsSleepTime = testApp.tps > 0 ? (UInt32)(ONE_NANO_SECOND / Double(testApp.tps)) : 0
    self.clientCount = testApp.clients
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
    (Mqtt5CanaryOperation.DESTROY_AND_CREATE, 10),
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
  let clientIndex = await Int.random(in: 0..<context.mqtt5CanaryClients.count)
  try await context.mqtt5CanaryRunOperation(
    options.operationDistribution[operationIndex], clientIndex, options)
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
    for _: Int in 0..<self.clients {
      try await context.createClient(testOptions: testOptions)
    }

    // Main Test iteration
    let startTime = Date()
    let endTime = startTime.addingTimeInterval(TimeInterval(self.seconds))

    while Date() < endTime {
      let iterationStartTime = Date()
      let targetTime = iterationStartTime.addingTimeInterval(
        TimeInterval(Double(testOptions.tpsSleepTime) / ONE_NANO_SECOND))
      Task {
        try await Mqtt5CanaryTestRunIteration(context, testOptions)
      }

      while Date() < targetTime {
        // Busy-wait for precision sleep
      }

    }

    // Close and clean up the clients
    for index: Int in 0..<self.clients {
      try await context.mqtt5CanaryRunOperation(Mqtt5CanaryOperation.STOP, index, testOptions)
    }

    // Print final statistics
    let actualDuration = Date().timeIntervalSince(startTime)
    await context.statistic.printStatistics(duration: actualDuration)

  }

}
