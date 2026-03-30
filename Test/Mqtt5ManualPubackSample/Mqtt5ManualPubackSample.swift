//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

/**
 Interactive MQTT5 Client Sample with Manual PUBACK Control

 This interactive sample demonstrates how to:
 1. Connect/disconnect to MQTT brokers with mTLS
 2. Subscribe/unsubscribe to topics
 3. Publish messages interactively
 4. Handle incoming messages with manual PUBACK control
 5. Send manual PUBACKs when ready

 Commands:
 - connect [session]               Connect to the MQTT broker (session: clean, rejoin)
 - disconnect                      Disconnect from the MQTT broker
 - subscribe <topic> [qos]         Subscribe to a topic (qos: 0, 1, default=1)
 - unsubscribe <topic>             Unsubscribe from a topic
 - publish <topic> <message> [qos] [retain]  Publish a message
 - puback <handle_id>              Send manual PUBACK for a received message
 - list                            List pending PUBACKs awaiting acknowledgment
 - status                          Show connection status
 - help                            Show available commands
 - quit / exit / q                 Exit the application

 Usage:
   swift run Mqtt5ManualPubackSample \
     --endpoint <broker-hostname> \
     --cert-file /path/to/cert.pem.crt \
     --key-file  /path/to/private.pem.key
 */

import ArgumentParser
import AwsCommonRuntimeKit
import Foundation

// MARK: - InteractiveMQTT5Client

/// Thread-safe actor that wraps an MQTT5 client and manages manual PUBACK state.
actor InteractiveMQTT5Client {

  // MARK: Configuration

  let endpoint: String
  let port: UInt32
  let certFile: String?
  let keyFile: String?
  let clientId: String

  // MARK: Runtime state

  private var client: Mqtt5Client?
  private(set) var isConnected: Bool = false

  /// Topics the client is currently subscribed to.
  private var subscriptions: Set<String> = []

  /// Pending PUBACK handles keyed by a user-visible sequence number.
  private var pendingPublishAcknowledgements: [Int: PublishAcknowledgementHandle] = [:]
  private var nextSequenceNum: Int = 1

  // MARK: Async-bridge continuations

  /// Resumed (or thrown into) when a connection attempt completes.
  private var connectContinuation: CheckedContinuation<Void, Error>?

  /// Resumed when the client fully stops.
  private var stopContinuation: CheckedContinuation<Void, Never>?

  // MARK: Init

  init(
    endpoint: String,
    port: UInt32 = 8883,
    certFile: String? = nil,
    keyFile: String? = nil,
    clientId: String? = nil
  ) {
    self.endpoint = endpoint
    self.port = port
    self.certFile = certFile
    self.keyFile = keyFile
    self.clientId =
      clientId ?? "swift-manual-puback-\(Int(Date().timeIntervalSince1970))"
  }

  // MARK: - Lifecycle callbacks (called from CRT threads via Task)

  func onConnectionSuccess(_ data: LifecycleConnectionSuccessData) {
    print("\n✅ Connected to MQTT5 broker!")
    print("   Session Present:          \(data.connackPacket.sessionPresent)")
    print("   Rejoined Session:         \(data.negotiatedSettings.rejoinedSession)")
    print(
      "   Session Expiry Interval:  \(data.negotiatedSettings.sessionExpiryInterval)s")
    print("   Client ID:                \(data.negotiatedSettings.clientId)")
    print("   Server Keep Alive:        \(data.negotiatedSettings.serverKeepAlive)s")
    print("   Maximum QoS:              \(data.negotiatedSettings.maximumQos)")
    print(
      "   Receive Maximum:          \(data.negotiatedSettings.receiveMaximumFromServer)")

    isConnected = true
    connectContinuation?.resume()
    connectContinuation = nil
  }

  func onConnectionFailure(_ data: LifecycleConnectionFailureData) {
    print("\n❌ Connection failed!")
    if let connack = data.connackPacket {
      print("   Reason: \(connack.reasonCode)")
      if let reasonString = connack.reasonString {
        print("   Details: \(reasonString)")
      }
    }
    print("   Error: \(data.crtError)")

    isConnected = false
    connectContinuation?.resume(throwing: CommonRunTimeError.crtError(data.crtError))
    connectContinuation = nil
  }

  func onDisconnection(_ data: LifecycleDisconnectData) {
    print("\n🔌 Disconnected from MQTT5 broker")
    if let disconnect = data.disconnectPacket {
      print("   Reason: \(disconnect.reasonCode)")
      if let reasonString = disconnect.reasonString {
        print("   Details: \(reasonString)")
      }
    }
    isConnected = false
  }

  func onStopped(_: LifecycleStoppedData) {
    print("\n🛑 Client stopped")
    stopContinuation?.resume()
    stopContinuation = nil
  }

  /// Called from the actor after the CRT callback has already acquired the PUBACK handle.
  ///
  /// - Parameters:
  ///   - packet: The received publish packet.
  ///   - publishAcknowledgementHandle: A handle obtained by calling `acquirePublishAcknowledgement()` synchronously
  ///     on the CRT event-loop thread inside `onPublishReceivedFn`. `nil` for QoS 0.
  func onPublishReceived(packet: PublishPacket, publishAcknowledgementHandle: PublishAcknowledgementHandle?) {
    let formatter = ISO8601DateFormatter()
    let timestamp = formatter.string(from: Date())

    var payloadStr = "<empty>"
    if let payload = packet.payload, !payload.isEmpty {
      payloadStr =
        String(data: payload, encoding: .utf8) ?? "<binary: \(payload.count) bytes>"
    }

    print("\n📨 Message received at \(timestamp):")
    print("   Topic:   \(packet.topic)")
    print("   QoS:     \(packet.qos)")
    print("   Payload: \(payloadStr)")
    print("   Retain:  \(packet.retain)")

    // Store the pre-acquired handle (already obtained on the event-loop thread).
    if let handle = publishAcknowledgementHandle {
      let seqNum = nextSequenceNum
      nextSequenceNum += 1
      pendingPublishAcknowledgements[seqNum] = handle

      print("   📋 Manual PUBACK control acquired — handle_id: \(seqNum)")
      print("   ⏳ Use 'puback \(seqNum)' to acknowledge this message")
      print("   📝 Use 'list' to see all pending PUBACKs")
    }
    print()
  }

  // MARK: - Public operations

  /// Connect to the MQTT5 broker.
  ///
  /// - Parameters:
  ///   - sessionBehavior: `.clean` or `.rejoinAlways` (default).
  func connect(sessionBehavior: ClientSessionBehaviorType = .rejoinAlways) async throws {
    guard !isConnected else {
      print("⚠️  Already connected")
      return
    }

    let sessionName: String
    switch sessionBehavior {
    case .clean: sessionName = "CLEAN"
    case .rejoinAlways: sessionName = "REJOIN_ALWAYS"
    case .rejoinPostSuccess: sessionName = "REJOIN_POST_SUCCESS"
    default: sessionName = "DEFAULT"
    }

    print("🔗 Connecting to \(endpoint):\(port) with client ID: \(clientId)")
    print("   Session behavior: \(sessionName)")

    // Build TLS context (mTLS when cert + key are provided, plain TLS otherwise).
    var tlsCtx: TLSContext? = nil
    if let cert = certFile, let key = keyFile {
      let tlsOptions = try TLSContextOptions.makeMTLS(
        certificatePath: cert,
        privateKeyPath: key
      )
      tlsCtx = try TLSContext(options: tlsOptions, mode: .client)
    }

    // CONNECT packet options.
    let connectOptions = MqttConnectOptions(
      keepAliveInterval: 30,
      clientId: clientId,
      sessionExpiryInterval: 3600,
      requestResponseInformation: true,
      requestProblemInformation: true
    )

    print("\n  Connecting to MQTT5 broker!")
    print("   Client ID:                \(clientId)")
    print("   Session Behavior:         \(sessionName)")
    print("   Session Expiry Interval:  3600s")

    // Capture self weakly so the callbacks don't extend the actor's lifetime.
    let clientOptions = MqttClientOptions(
      hostName: endpoint,
      port: port,
      tlsCtx: tlsCtx,
      connectOptions: connectOptions,
      sessionBehavior: sessionBehavior,
      retryJitterMode: .full,
      minReconnectDelay: 1.0,
      maxReconnectDelay: 30.0,
      pingTimeout: 10.0,
      connackTimeout: 10.0,
      ackTimeout: 30.0,
      onPublishReceivedFn: { [weak self] data in
        guard let self else { return }
        // acquirePublishAcknowledgement() MUST be called here, synchronously on the CRT
        // event-loop thread. The closure becomes invalid once this callback returns.
        let publishAcknowledgementHandle: PublishAcknowledgementHandle?
        if data.publishPacket.qos == .atLeastOnce {
          publishAcknowledgementHandle = data.acquirePublishAcknowledgement?()
        } else {
          publishAcknowledgementHandle = nil
        }
        let packet = data.publishPacket
        Task { await self.onPublishReceived(packet: packet, publishAcknowledgementHandle: publishAcknowledgementHandle) }
      },
      onLifecycleEventStoppedFn: { [weak self] data in
        guard let self else { return }
        Task { await self.onStopped(data) }
      },
      onLifecycleEventAttemptingConnectFn: { _ in
        print("\n🔄 Attempting to connect...")
      },
      onLifecycleEventConnectionSuccessFn: { [weak self] data in
        guard let self else { return }
        Task { await self.onConnectionSuccess(data) }
      },
      onLifecycleEventConnectionFailureFn: { [weak self] data in
        guard let self else { return }
        Task { await self.onConnectionFailure(data) }
      },
      onLifecycleEventDisconnectionFn: { [weak self] data in
        guard let self else { return }
        Task { await self.onDisconnection(data) }
      }
    )

    // Create the native client (only once per connect call).
    client = try Mqtt5Client(clientOptions: clientOptions)

    // Start the client and suspend until the connection succeeds or fails.
    try await withCheckedThrowingContinuation {
      (continuation: CheckedContinuation<Void, Error>) in
      self.connectContinuation = continuation
      do {
        try self.client?.start()
      } catch {
        self.connectContinuation = nil
        continuation.resume(throwing: error)
      }
    }
  }

  /// Disconnect from the MQTT5 broker.
  func disconnect() async {
    guard let client else {
      print("❌ No client to disconnect")
      return
    }
    guard isConnected else {
      print("⚠️  Already disconnected")
      return
    }

    print("🔌 Disconnecting...")

    let disconnectPacket = DisconnectPacket(
      reasonCode: .normalDisconnection,
      sessionExpiryInterval: 3600
    )

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      self.stopContinuation = continuation
      do {
        try client.stop(disconnectPacket: disconnectPacket)
      } catch {
        print("❌ Stop failed: \(error)")
        self.stopContinuation = nil
        continuation.resume()
      }
    }

    isConnected = false
    subscriptions.removeAll()
  }

  /// Subscribe to a topic filter.
  func subscribe(topicFilter: String, qos: QoS = .atLeastOnce) async {
    guard isConnected, let client else {
      print("❌ Cannot subscribe: not connected")
      return
    }

    print("📝 Subscribing to topic: \(topicFilter) (QoS \(qos))")

    let subscribePacket = SubscribePacket(topicFilter: topicFilter, qos: qos)

    do {
      let suback = try await client.subscribe(subscribePacket: subscribePacket)
      for reasonCode in suback.reasonCodes {
        switch reasonCode {
        case .grantedQos0, .grantedQos1, .grantedQos2:
          print("✅ Subscription successful: \(reasonCode)")
          subscriptions.insert(topicFilter)
        default:
          print("❌ Subscription failed: \(reasonCode)")
        }
      }
    } catch {
      print("❌ Subscribe error: \(error)")
    }
  }

  /// Unsubscribe from a topic filter.
  func unsubscribe(topicFilter: String) async {
    guard isConnected, let client else {
      print("❌ Cannot unsubscribe: not connected")
      return
    }

    print("🚫 Unsubscribing from topic: \(topicFilter)")

    let unsubscribePacket = UnsubscribePacket(topicFilter: topicFilter)

    do {
      let unsuback = try await client.unsubscribe(unsubscribePacket: unsubscribePacket)
      for reasonCode in unsuback.reasonCodes {
        switch reasonCode {
        case .success:
          print("✅ Unsubscribe successful: \(reasonCode)")
          subscriptions.remove(topicFilter)
        case .noSubscriptionExisted:
          print("⚠️  No subscription existed for: \(topicFilter)")
          subscriptions.remove(topicFilter)
        default:
          print("❌ Unsubscribe failed: \(reasonCode)")
        }
      }
    } catch {
      print("❌ Unsubscribe error: \(error)")
    }
  }

  /// Publish a message to a topic.
  func publish(
    topic: String,
    payload: String,
    qos: QoS = .atLeastOnce,
    retain: Bool = false
  ) async {
    guard isConnected, let client else {
      print("❌ Cannot publish: not connected")
      return
    }

    print("📤 Publishing to topic: \(topic)")
    print("   Payload: \(payload)")
    print("   QoS: \(qos), Retain: \(retain)")

    let publishPacket = PublishPacket(
      qos: qos,
      topic: topic,
      payload: payload.data(using: .utf8),
      retain: retain
    )

    do {
      let result = try await client.publish(publishPacket: publishPacket)
      if qos == .atLeastOnce, let puback = result.puback {
        print("✅ Publish acknowledged: \(puback.reasonCode)")
      } else {
        print("✅ Publish sent (QoS 0)")
      }
    } catch {
      print("❌ Publish error: \(error)")
    }
  }

  /// Send a manual PUBACK for a previously received QoS 1 message.
  ///
  /// - Parameter handleId: The sequence number shown when the message arrived.
  func invokePublishAcknowledgement(handleId: Int) async {
    guard let handle = pendingPublishAcknowledgements[handleId] else {
      print("❌ Invalid handle_id: \(handleId)")
      print("   Use 'list' to see pending PUBACKs")
      return
    }

    guard let client else {
      print("❌ No active client")
      return
    }

    print("📤 Sending PUBACK for handle_id: \(handleId)")
    do {
      try client.invokePublishAcknowledgement(handle)
      pendingPublishAcknowledgements.removeValue(forKey: handleId)
      print("✅ PUBACK sent successfully")
    } catch {
      print("❌ PUBACK failed: \(error)")
    }
  }

  // MARK: - Display helpers

  func showStatus() {
    let icon = isConnected ? "✅" : "❌"
    let text = isConnected ? "Connected" : "Disconnected"
    print("\(icon) Status: \(text)")
    if isConnected {
      print("   Endpoint:      \(endpoint):\(port)")
      print("   Client ID:     \(clientId)")
      print("   Subscriptions: \(subscriptions.count)")
      for topic in subscriptions.sorted() {
        print("     - \(topic)")
      }
    }
  }

  func showPendingPubacks() {
    if pendingPublishAcknowledgements.isEmpty {
      print("📭 No pending PUBACKs")
      return
    }
    print("📋 Pending PUBACKs (\(pendingPublishAcknowledgements.count)):")
    for id in pendingPublishAcknowledgements.keys.sorted() {
      print("   \(id): Use 'puback \(id)' to acknowledge")
    }
  }

  func showHelp() {
    print(
      """

      📖 Available Commands:

      Connection Management:
        connect [session]                    Connect to the MQTT broker
                                             session: clean, rejoin (default=rejoin)
        disconnect                           Disconnect from the MQTT broker
        status                               Show connection status

      Topic Operations:
        subscribe <topic> [qos]              Subscribe to a topic (qos: 0, 1, default=1)
        unsubscribe <topic>                  Unsubscribe from a topic

      Publishing:
        publish <topic> <message> [qos] [retain]
                                             Publish a message
                                             qos: 0, 1 (default=1)
                                             retain: true, false (default=false)

      Manual PUBACK Control:
        puback <handle_id>                   Send manual PUBACK for a received message
        list                                 List pending PUBACKs awaiting acknowledgment

      General:
        help                                 Show this help message
        quit / exit / q                      Exit the application

      Examples:
        connect
        connect clean
        connect rejoin
        subscribe test/topic
        subscribe test/topic 0
        publish test/topic "Hello World"
        publish test/topic "Hello" 1 true
        puback 1
      """)
  }
}

// MARK: - InteractiveCLI

/// Reads commands from stdin and dispatches them to the MQTT5 client actor.
struct InteractiveCLI {

  let client: InteractiveMQTT5Client

  // MARK: Helpers

  private func parseQoS(_ string: String) -> QoS {
    switch string {
    case "0": return .atMostOnce
    case "1": return .atLeastOnce
    default: return .atLeastOnce
    }
  }

  private func parseBool(_ string: String) -> Bool {
    return ["true", "yes", "1", "on"].contains(string.lowercased())
  }

  private func parseSessionBehavior(_ string: String) -> ClientSessionBehaviorType {
    switch string.lowercased() {
    case "clean": return .clean
    case "rejoin": return .rejoinAlways
    default: return .rejoinAlways
    }
  }

  /// Read a line from stdin without blocking the Swift cooperative thread pool.
  private func readLineAsync(prompt: String) async -> String? {
    print(prompt, terminator: "")
    // Flush stdout so the prompt appears before we block.
    fflush(stdout)
    return await withCheckedContinuation { continuation in
      DispatchQueue.global(qos: .userInteractive).async {
        let line = readLine(strippingNewline: true)
        continuation.resume(returning: line)
      }
    }
  }

  // MARK: Command dispatch

  /// Execute a single command line.
  func runCommand(_ commandLine: String) async {
    let parts = commandLine.trimmingCharacters(in: .whitespaces).split(
      separator: " ", omittingEmptySubsequences: true
    ).map(String.init)

    guard !parts.isEmpty else { return }

    let cmd = parts[0].lowercased()
    let args = Array(parts.dropFirst())

    switch cmd {

    case "quit", "exit", "q":
      // Handled in the run loop; reaching here means the loop already exited.
      break

    case "help":
      await client.showHelp()

    case "status":
      await client.showStatus()

    case "connect":
      let behavior =
        args.isEmpty ? ClientSessionBehaviorType.rejoinAlways : parseSessionBehavior(args[0])
      do {
        try await client.connect(sessionBehavior: behavior)
      } catch {
        print("❌ Connect failed: \(error)")
      }

    case "disconnect":
      await client.disconnect()

    case "subscribe":
      guard !args.isEmpty else {
        print("❌ Usage: subscribe <topic> [qos]")
        return
      }
      let topic = args[0]
      let qos = args.count > 1 ? parseQoS(args[1]) : .atLeastOnce
      await client.subscribe(topicFilter: topic, qos: qos)

    case "unsubscribe":
      guard !args.isEmpty else {
        print("❌ Usage: unsubscribe <topic>")
        return
      }
      await client.unsubscribe(topicFilter: args[0])

    case "publish":
      guard args.count >= 2 else {
        print("❌ Usage: publish <topic> <message> [qos] [retain]")
        return
      }
      let topic = args[0]
      let message = args[1]
      let qos: QoS = args.count > 2 ? parseQoS(args[2]) : .atLeastOnce
      let retain: Bool = args.count > 3 ? parseBool(args[3]) : false
      await client.publish(topic: topic, payload: message, qos: qos, retain: retain)

    case "puback":
      guard let idStr = args.first, let handleId = Int(idStr) else {
        print("❌ Usage: puback <handle_id>  (handle_id must be a number)")
        return
      }
      await client.invokePublishAcknowledgement(handleId: handleId)

    case "list":
      await client.showPendingPubacks()

    default:
      print("❌ Unknown command: '\(cmd)'. Type 'help' for available commands.")
    }
  }

  // MARK: REPL

  /// Run the interactive command loop until the user quits.
  func runInteractive() async {
    print("\n🎮 Interactive MQTT5 Client — Type 'help' for commands")
    print(String(repeating: "=", count: 60))

    while true {
      let connected = await client.isConnected
      let icon = connected ? "🟢" : "🔴"
      let prompt = "\(icon) mqtt5> "

      guard let line = await readLineAsync(prompt: prompt) else {
        // EOF (Ctrl-D)
        print("\n👋 EOF received, exiting...")
        break
      }

      let trimmed = line.trimmingCharacters(in: .whitespaces)
      if trimmed.isEmpty { continue }

      let cmd = trimmed.split(separator: " ").first.map(String.init)?.lowercased() ?? ""
      if cmd == "quit" || cmd == "exit" || cmd == "q" {
        if await client.isConnected {
          print("🔌 Disconnecting before exit...")
          await client.disconnect()
        }
        break
      }

      await runCommand(trimmed)
    }

    print("👋 Goodbye!")
  }
}

// MARK: - Entry Point

@main
struct Mqtt5ManualPubackSample: AsyncParsableCommand {

  static let configuration = CommandConfiguration(
    commandName: "Mqtt5ManualPubackSample",
    abstract: "Interactive MQTT5 client with manual PUBACK control",
    discussion: """
      Connects to an MQTT5 broker and provides an interactive CLI for
      subscribing, publishing, and manually acknowledging QoS 1 messages.

      Example:
        Mqtt5ManualPubackSample \\
          --endpoint a1b2c3d4e5f6g7-ats.iot.us-east-1.amazonaws.com \\
          --cert-file ~/certs/device.pem.crt \\
          --key-file  ~/certs/device.pem.key
      """
  )

  @Option(name: [.long, .short], help: "MQTT broker hostname (required).")
  var endpoint: String

  @Option(name: [.long, .short], help: "MQTT broker port (default: 8883).")
  var port: UInt32 = 8883

  @Option(name: .long, help: "Path to the client certificate file (PEM format).")
  var certFile: String? = nil

  @Option(name: .long, help: "Path to the private key file (PEM format).")
  var keyFile: String? = nil

  @Option(
    name: [.long, .customShort("c")],
    help: "MQTT client ID (default: auto-generated with timestamp).")
  var clientId: String? = nil

  mutating func run() async throws {
    // Initialise the AWS Common Runtime.
    CommonRuntimeKit.initialize()

    print("🚀 Interactive MQTT5 Client with Manual PUBACK Control")
    print(String(repeating: "=", count: 60))
    print("📡 Endpoint:    \(endpoint):\(port)")
    if let cert = certFile {
      print("🔐 Certificate: \(cert)")
    }
    if let key = keyFile {
      print("🗝️  Key:         \(key)")
    }
    if let id = clientId {
      print("🏷️  Client ID:   \(id)")
    } else {
      print("🏷️  Client ID:   Auto-generated")
    }

    // Create the client actor.
    let mqttClient = InteractiveMQTT5Client(
      endpoint: endpoint,
      port: port,
      certFile: certFile,
      keyFile: keyFile,
      clientId: clientId
    )

    // Run the interactive CLI.
    let cli = InteractiveCLI(client: mqttClient)
    await cli.runInteractive()
  }
}
