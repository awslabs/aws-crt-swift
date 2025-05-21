///  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
///  SPDX-License-Identifier: Apache-2.0.
import AwsCMqtt
import LibNative
import Foundation

/// The type of change to the state of a streaming operation subscription
public enum SubscriptionStatusEventType: Sendable {
  /// The streaming operation is successfully subscribed to its topic (filter)
  case established

  /// The streaming operation has temporarily lost its subscription to its topic (filter)
  case lost

  /// The streaming operation has entered a terminal state where it has given up trying to subscribe
  /// to its topic (filter).  This is always due to user error (bad topic filter or IoT Core permission policy).
  case halted
}

extension SubscriptionStatusEventType {
  /// Returns the native representation of the Swift enum
  var rawValue: aws_rr_streaming_subscription_event_type {
    switch self {
    case .established: return ARRSSET_SUBSCRIPTION_ESTABLISHED
    case .lost: return ARRSSET_SUBSCRIPTION_LOST
    case .halted: return ARRSSET_SUBSCRIPTION_HALTED
    }
  }

  /// Initializes Swift enum from native representation
  init(_ cEnum: aws_rr_streaming_subscription_event_type) {
    switch cEnum {
    case ARRSSET_SUBSCRIPTION_ESTABLISHED:
      self = .established
    case ARRSSET_SUBSCRIPTION_LOST:
      self = .lost
    case ARRSSET_SUBSCRIPTION_HALTED:
      self = .halted
    default:
      fatalError("Unknown Susbscription Event Type")
    }
  }
}

/// An event that describes a change in subscription status for a streaming operation.
public struct SubscriptionStatusEvent: Sendable {
  /// The type of the event
  public let event: SubscriptionStatusEventType

  /// An optional error code associated with the event. Only set for SubscriptionLost and SubscriptionHalted.
  public let error: CRTError?
}

/// An event that describes an incoming publish message received on a streaming operation.
public struct IncomingPublishEvent: Sendable {

  /// The topic associated with this PUBLISH packet.
  public let topic: String

  /// The payload of the publish message in a byte buffer format
  public let payload: Data

  /// (Optional) The content type of the payload
  public let contentType: String?

  /// (Optional) User Properties, if there is no user property, the array will be empty
  public let userProperties: [UserProperty]

  /// (Optional) Some services use this field to specify client-side timeouts.
  public let messageExpiryInterval: TimeInterval?

  /// Internal constructor that setup IncomingPublishEvent from native aws_mqtt_rr_incoming_publish_event
  init(_ raw_publish_event: UnsafePointer<aws_mqtt_rr_incoming_publish_event>) {
    let publish_event = raw_publish_event.pointee

    self.topic = publish_event.topic.toString()
    self.payload = Data(bytes: publish_event.payload.ptr, count: publish_event.payload.len)
    self.messageExpiryInterval = (publish_event.message_expiry_interval_seconds?.pointee).map {
      TimeInterval($0)
    }
    self.contentType = publish_event.content_type?.pointee.toString()
    self.userProperties = convertOptionalUserProperties(
      count: publish_event.user_property_count,
      userPropertiesPointer: publish_event.user_properties)
  }
}

/// Function signature of a SubscriptionStatusEvent event handler
public typealias SubscriptionStatusEventHandler = @Sendable (SubscriptionStatusEvent) -> Void

/// Function signature of an IncomingPublishEvent event handler
public typealias IncomingPublishEventHandler = @Sendable (IncomingPublishEvent) -> Void

/// A response to an AWS IoT Core MQTT-based service request
public struct MqttRequestResponse: Sendable {
  /// The MQTT Topic that the response was received on.
  public let topic: String
  /// Payload of the response that correlates to a submitted request.
  public let payload: Data

  /// Internal constructor that setup MqttRequestResponse from native aws_mqtt_rr_incoming_publish_event
  init(_ raw_publish_event: UnsafePointer<aws_mqtt_rr_incoming_publish_event>) {
    let publish_event = raw_publish_event.pointee
    self.topic = publish_event.topic.toString()
    self.payload = Data(bytes: publish_event.payload.ptr, count: publish_event.payload.len)
  }
}

// We can't mutate this class after initialization. Swift can not verify the sendability due to direct use of c pointer,
// so mark it unchecked Sendable
/// A response path is a pair of values - MQTT topic and a JSON path - that describe where a response to
/// an MQTT-based request may arrive.  For a given request type, there may be multiple response paths and each
/// one is associated with a separate JSON schema for the response body.
final public class ResponsePath: CStruct, @unchecked Sendable {
  /// MQTT topic that a response may arrive on.
  let topic: String
  /// JSON path for finding correlation tokens within payloads that arrive on this path's topic.
  let correlationTokenJsonPath: String

  /// Create a response path
  ///
  /// - Parameters:
  ///     - topic: MQTT topic that a response may arrive on.
  ///     - correlationTokenJsonPath: JSON path for finding correlation tokens within payloads that arrive on this path's topic.
  public init(topic: String, correlationTokenJsonPath: String) {
    self.topic = topic
    self.correlationTokenJsonPath = correlationTokenJsonPath

    withByteCursorFromStrings(self.topic, self.correlationTokenJsonPath) {
      cTopicCursor, cCorrelationTokenCursor in
      aws_byte_buf_init_copy_from_cursor(&self.topic_buffer, allocator, cTopicCursor)
      aws_byte_buf_init_copy_from_cursor(
        &self.correlation_token_buffer, allocator, cCorrelationTokenCursor)
    }
  }

  typealias RawType = aws_mqtt_request_operation_response_path
  func withCStruct<Result>(_ body: (aws_mqtt_request_operation_response_path) -> Result) -> Result {
    var raw_option = aws_mqtt_request_operation_response_path()
    raw_option.topic = aws_byte_cursor_from_buf(&self.topic_buffer)
    raw_option.correlation_token_json_path = aws_byte_cursor_from_buf(
      &self.correlation_token_buffer)
    return body(raw_option)
  }

  // We keep a memory of the buffer storage in the class, and release it on
  // destruction
  private var topic_buffer: aws_byte_buf = aws_byte_buf()
  private var correlation_token_buffer: aws_byte_buf = aws_byte_buf()

  deinit {
    aws_byte_buf_clean_up(&topic_buffer)
    aws_byte_buf_clean_up(&correlation_token_buffer)
  }
}

/// Configuration options for request response operation
public struct RequestResponseOperationOptions: CStructWithUserData, Sendable {
  /// Topic filters that should be subscribed to in order to cover all possible response paths.  Sometimes we can use wildcards to
  /// cut down on the subscriptions needed; sometimes we can't.
  let subscriptionTopicFilters: [String]
  /// All possible response paths associated with this request type
  let responsePaths: [ResponsePath]
  /// Topic to publish the request to once response subscriptions have been established.
  let topic: String
  /// Payload to publish in order to initiate the request
  let payload: Data
  /// Correlation token embedded in the request that must be found in a response message.  This can be the empty cursor to support certain services
  /// which don't use correlation tokens.  In this case, the client only allows one request at a time to use the associated subscriptions; no concurrency
  /// is possible.  There are some optimizations we could make here but for now, they're not worth the complexity.
  let correlationToken: String?

  /// Create a configuration options for request response operation
  ///
  /// - Parameters:
  ///     - subscriptionTopicFilters: Topic filters that should be subscribed to in order to cover all possible response paths.  Sometimes we can use wildcards to cut
  ///     down on the subscriptions needed; sometimes we can't.
  ///     - responsePaths: All possible response paths associated with this request type.
  ///     - topic: Topic to publish the request to once response subscriptions have been established.
  ///     - payload: Payload to publish in order to initiate the request
  ///     - correlationToken: Correlation token embedded in the request that must be found in a response message.  This can be the empty cursor to support certain
  ///     services which don't use correlation tokens.  In this case, the client only allows one request at a time to use the associated subscriptions; no concurrency is
  ///     possible.  There are some optimizations we could make here but for now, they're not worth the complexity.
  public init(
    subscriptionTopicFilters: [String],
    responsePaths: [ResponsePath],
    topic: String,
    payload: Data,
    correlationToken: String?
  ) {
    self.subscriptionTopicFilters = subscriptionTopicFilters
    self.responsePaths = responsePaths
    self.topic = topic
    self.payload = payload
    self.correlationToken = correlationToken
  }

  func validateConversionToNative() throws {
  }

  typealias RawType = aws_mqtt_request_operation_options
  func withCStruct<Result>(userData: UnsafeMutableRawPointer?, _ body: (RawType) -> Result)
    -> Result
  {
    var raw_options = aws_mqtt_request_operation_options()
    return self.subscriptionTopicFilters.withMutableByteCursorArray { topicsCursor, len in
      raw_options.subscription_topic_filters = topicsCursor
      raw_options.subscription_topic_filter_count = len
      return self.responsePaths.withAWSArrayList { responsePathPointer in
        raw_options.response_paths = UnsafeMutablePointer<aws_mqtt_request_operation_response_path>(
          responsePathPointer)
        raw_options.response_path_count = self.responsePaths.count

        return withByteCursorFromStrings(self.topic, self.correlationToken) {
          topicCursor, correlationCursor in
          raw_options.publish_topic = topicCursor
          raw_options.correlation_token = correlationCursor

          return withAWSByteCursorFromOptionalData(to: self.payload) { cByteCursor in
            raw_options.serialized_request = cByteCursor

            if let userData {
              raw_options.user_data = userData
              raw_options.completion_callback = MqttRROperationCompletionCallback
            }
            return body(raw_options)
          }
        }
      }
    }
  }
}

private func MqttRRStreamingOperationTerminationCallback(_ userData: UnsafeMutableRawPointer?) {
  // Termination callback. This is triggered when the native object is terminated.
  // It is safe to release the native operation at this point. `takeRetainedValue()` would release
  // the operation reference. ONLY DO IT AFTER YOU NEED RELEASE THE OBJECT
  _ = Unmanaged<StreamingOperationCore>.fromOpaque(userData!).takeRetainedValue()
}

private func MqttRRStreamingOperationIncomingPublishCallback(
  _ publishEvent: UnsafePointer<aws_mqtt_rr_incoming_publish_event>?,
  _ userData: UnsafeMutableRawPointer?
) {
  guard let userData, let publishEvent else {
    // No userData, directly return
    return
  }
  let operationCore = Unmanaged<StreamingOperationCore>.fromOpaque(userData).takeUnretainedValue()
  operationCore.rwlock.read {
    // Only invoke the callback if the streaming operation is not closed.
    if operationCore.rawValue != nil, operationCore.options.incomingPublishEventHandler != nil {
      let subStatusEvent = IncomingPublishEvent(publishEvent)
      operationCore.options.incomingPublishEventHandler(subStatusEvent)
    }
  }
}

private func MqttRRStreamingOperationSubscriptionStatusCallback(
  _ eventType: aws_rr_streaming_subscription_event_type,
  _ errorCode: Int32,
  _ userData: UnsafeMutableRawPointer?
) {
  guard let userData else {
    // No userData, directly return
    return
  }
  let operationCore = Unmanaged<StreamingOperationCore>.fromOpaque(userData).takeUnretainedValue()
  operationCore.rwlock.read {
    // Only invoke the callback if the streaming operation is not closed.
    if operationCore.rawValue != nil, operationCore.options.subscriptionStatusEventHandler != nil {
      let subStatusEvent = SubscriptionStatusEvent(
        event: SubscriptionStatusEventType(eventType),
        error: errorCode == 0 ? nil : CRTError(code: Int32(errorCode)))
      operationCore.options.subscriptionStatusEventHandler(subStatusEvent)
    }
  }
}

/// Configuration options for streaming operations
public struct StreamingOperationOptions: CStructWithUserData, Sendable {
  /// The MQTT topic that the streaming is "listen" to.
  public let topicFilter: String
  /// The handler function a streaming operation will use for subscription status events.
  public let subscriptionStatusEventHandler: SubscriptionStatusEventHandler
  /// The handler function a streaming operation will use for the incoming message
  public let incomingPublishEventHandler: IncomingPublishEventHandler

  public init(
    topicFilter: String,
    subscriptionStatusCallback: @escaping SubscriptionStatusEventHandler,
    incomingPublishCallback: @escaping IncomingPublishEventHandler
  ) {
    self.subscriptionStatusEventHandler = subscriptionStatusCallback
    self.incomingPublishEventHandler = incomingPublishCallback
    self.topicFilter = topicFilter
  }

  typealias RawType = aws_mqtt_streaming_operation_options
  func withCStruct<Result>(
    userData: UnsafeMutableRawPointer?, _ body: (aws_mqtt_streaming_operation_options) -> Result
  ) -> Result {
    var options = aws_mqtt_streaming_operation_options()
    options.incoming_publish_callback = MqttRRStreamingOperationIncomingPublishCallback
    options.subscription_status_callback = MqttRRStreamingOperationSubscriptionStatusCallback
    options.terminated_callback = MqttRRStreamingOperationTerminationCallback
    return withByteCursorFromStrings(self.topicFilter) { topicFilterCursor in
      options.topic_filter = topicFilterCursor
      options.user_data = userData
      return body(options)
    }
  }
}

// IMPORTANT: You are responsible for concurrency correctness of StreamingOperationCore.
// The rawValue is mutable cross threads and protected by the rwlock.
/// The internal core of the streaming operation. It helps to handle the aws_mqtt_rr_client_operation termination.
private class StreamingOperationCore: @unchecked Sendable {
  fileprivate var rawValue: OpaquePointer?  // <aws_mqtt_rr_client_operation>?
  fileprivate let rwlock = ReadWriteLock()
  fileprivate let options: StreamingOperationOptions

  fileprivate init(streamOptions: StreamingOperationOptions, client: MqttRequestResponseClientCore)
    throws
  {
    self.options = streamOptions
    let rawValue = streamOptions.withCPointer(
      userData: Unmanaged<StreamingOperationCore>.passRetained(self).toOpaque()
    ) { optionsPointer in
      return aws_mqtt_request_response_client_create_streaming_operation(
        client.rawValue, optionsPointer)
    }
    guard let rawValue else {
      throw CommonRunTimeError.crtError(CRTError(code: aws_last_error()))
    }
    self.rawValue = rawValue
  }

  /// Opens a streaming operation by making the appropriate MQTT subscription with the broker.
  fileprivate func open() throws {
    try rwlock.read {
      if let rawValue = self.rawValue {
        if aws_mqtt_rr_client_operation_activate(rawValue) != AWS_OP_SUCCESS {
          throw CommonRunTimeError.crtError(CRTError(code: aws_last_error()))
        }
      }
    }
  }

  /// Closes the operation
  fileprivate func close() {
    rwlock.write {
      aws_mqtt_rr_client_operation_release(self.rawValue)
      self.rawValue = nil
    }
  }
}

/// The streaming operation, it is automatically closed (and an MQTT unsubscribe triggered) when its destructor is invoked.
public class StreamingOperation {
  fileprivate var operationCore: StreamingOperationCore

  /// Constructor. The end user should only create the operation through MqttRequestResponseClient->createStream()
  fileprivate init(streamOptions: StreamingOperationOptions, client: MqttRequestResponseClientCore)
    throws
  {
    self.operationCore = try StreamingOperationCore(streamOptions: streamOptions, client: client)
  }

  /// Opens a streaming operation by making the appropriate MQTT subscription with the broker.
  /// - Throws: CommonRunTimeError
  public func open() throws {
    try self.operationCore.open()
  }

  deinit {
    self.operationCore.close()
  }
}

/// MQTT-based request-response client configuration options
final public class MqttRequestResponseClientOptions: CStructWithUserData, Sendable {

  /// Maximum number of request-response subscriptions the client allows to be concurrently active at any one point in time. When the client hits this threshold,
  /// requests will be delayed until earlier requests complete and release their subscriptions.  Each in-progress request will use either 1 or 2 MQTT subscriptions
  /// until completion.
  /// Default to 3.
  public let maxRequestResponseSubscription: Int

  /// Maximum number of concurrent streaming operation subscriptions that the client will allow. Each "unique" (different topic filter) streaming operation will use
  /// 1 MQTT subscription.  When the client hits this threshold, attempts to open new streaming operations will fail.
  /// Default to 2.
  public let maxStreamingSubscription: Int

  /// The timeout value, in seconds, for a request-response operation. If a request is not complete by this time interval, the client will complete it as failed.
  /// This time interval starts the instant the request is submitted to the client.
  /// Default to 60 seconds.
  public let operationTimeout: TimeInterval

  public init(
    maxRequestResponseSubscription: Int = 3, maxStreamingSubscription: Int = 2,
    operationTimeout: TimeInterval = 60
  ) {
    self.maxStreamingSubscription = maxStreamingSubscription
    self.maxRequestResponseSubscription = maxRequestResponseSubscription
    self.operationTimeout = operationTimeout
  }

  func validateConversionToNative() throws {
    do {
      _ = try self.operationTimeout.secondUInt32()
    } catch {
      throw CommonRunTimeError.crtError(
        CRTError(
          code: AWS_ERROR_INVALID_ARGUMENT.rawValue,
          context: "Invalid operationTimeout value"))
    }
  }

  typealias RawType = aws_mqtt_request_response_client_options
  func withCStruct<Result>(
    userData: UnsafeMutableRawPointer?, _ body: (aws_mqtt_request_response_client_options) -> Result
  ) -> Result {
    var options = aws_mqtt_request_response_client_options()
    options.max_request_response_subscriptions = self.maxRequestResponseSubscription
    options.max_streaming_subscriptions = self.maxStreamingSubscription
    if let _operationTimeout: UInt32 = try? self.operationTimeout.secondUInt32() {
      options.operation_timeout_seconds = _operationTimeout
    }
    options.terminated_callback = MqttRRClientTerminationCallback
    options.user_data = userData
    return body(options)
  }
}

private func MqttRRClientTerminationCallback(_ userData: UnsafeMutableRawPointer?) {
  // Termination callback. This is triggered when the native client is terminated.
  // It is safe to release the request response client at this point.
  // `takeRetainedValue()` would release the client reference. ONLY DO IT AFTER YOU NEED RELEASE THE CLIENT
  _ = Unmanaged<MqttRequestResponseClientCore>.fromOpaque(userData!).takeRetainedValue()
}

private func MqttRROperationCompletionCallback(
  publishEvent: UnsafePointer<aws_mqtt_rr_incoming_publish_event>?,
  errorCode: Int32,
  userData: UnsafeMutableRawPointer?
) {
  guard let userData else {
    return
  }
  let continuationCore = Unmanaged<ContinuationCore<MqttRequestResponse>>.fromOpaque(
    userData
  ).takeRetainedValue()
  if errorCode != AWS_OP_SUCCESS {
    return continuationCore.continuation.resume(
      throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
  }

  if let publishEvent {
    let response: MqttRequestResponse = MqttRequestResponse(publishEvent)
    return continuationCore.continuation.resume(returning: response)
  }

  assertionFailure(
    "MqttRROperationCompletionCallback: The topic and paylaod should be set if operation succeed")
}

// IMPORTANT: You are responsible for ensuring the concurrency correctness of MqttRequestResponseClientCore.
// The rawValue is only modified within the close() function, which is exclusively called in the MqttRequestResponseClient destructor.
// At that point, no other operations should be in progress. Therefore, under this usage model, MqttRequestResponseClientCore is
// expected to be thread-safe.
/// The internal core of the mqtt request response client. It helps to handle the native request response termination.
private class MqttRequestResponseClientCore: @unchecked Sendable {
  fileprivate var rawValue: OpaquePointer?  // aws_mqtt_request_response_client

  fileprivate init(mqttClient: Mqtt5Client, options: MqttRequestResponseClientOptions) throws {
    guard
      let rawValue =
        (options.withCPointer(
          userData: Unmanaged<MqttRequestResponseClientCore>.passRetained(self).toOpaque()
        ) { optionsPointer in
          return aws_mqtt_request_response_client_new_from_mqtt5_client(
            allocator, mqttClient.clientCore.rawValue, optionsPointer)
        })
    else {
      // Failed to create client, release the callback core
      Unmanaged<MqttRequestResponseClientCore>.passUnretained(self).release()
      throw CommonRunTimeError.crtError(.makeFromLastError())
    }
    self.rawValue = rawValue
  }

  /// Submits a request responds operation, throws CRTError if the operation failed
  fileprivate func submitRequest(operationOptions: RequestResponseOperationOptions) async throws
    -> MqttRequestResponse
  {
    try operationOptions.validateConversionToNative()
    return try await withCheckedThrowingContinuation { continuation in
      let continuationCore = ContinuationCore<MqttRequestResponse>(
        continuation: continuation)
      operationOptions.withCPointer(
        userData: continuationCore.passRetained(),
        { optionsPointer in
          let result = aws_mqtt_request_response_client_submit_request(
            self.rawValue, optionsPointer)
          if result != AWS_OP_SUCCESS {
            continuationCore.release()
            return continuation.resume(
              throwing: CommonRunTimeError.crtError(CRTError.makeFromLastError()))
          }
        })
    }
  }

  /// Creates a stream operation, throws CRTError if the creation failed. You will need to call open() on the operation to start the stream
  fileprivate func createStream(streamOptions: StreamingOperationOptions) throws
    -> StreamingOperation
  {
    return try StreamingOperation(streamOptions: streamOptions, client: self)
  }

  /// Releases the request response client. You must not use the client after calling `close()`.
  fileprivate func close() {
    aws_mqtt_request_response_client_release(self.rawValue)
    self.rawValue = nil
  }

}

/// The MqttRequestResponseClient is a client that allows you to send requests and receive responses over MQTT.
public class MqttRequestResponseClient {
  fileprivate var clientCore: MqttRequestResponseClientCore

  /// Creates a new request-response client using an MQTT5 client for protocol transport
  ///
  /// - Parameters:
  ///     - mqtt5Client: the MQTT5 client that use for protocol transport
  ///     - options: request-response client configurations
  ///
  /// - Returns: MqttRequestResponseClient
  ///
  /// - Throws: CommonRuntimeError.crtError if creation failed
  public static func newFromMqtt5Client(
    mqtt5Client: Mqtt5Client,
    options: MqttRequestResponseClientOptions? = nil
  ) throws -> MqttRequestResponseClient {
    return try MqttRequestResponseClient(
      mqttClient: mqtt5Client, options: options ?? MqttRequestResponseClientOptions())
  }

  init(mqttClient: Mqtt5Client, options: MqttRequestResponseClientOptions) throws {
    clientCore = try MqttRequestResponseClientCore(mqttClient: mqttClient, options: options)
  }

  /// Submits a generic request to the request-response client, throws CRTError if the operation failed
  ///
  /// - Parameters:
  ///     - operationOptions: configuration options for request response operation
  /// - Returns: MqttRequestResponse
  /// - Throws: CommonRuntimeError.crtError if submit failed
  public func submitRequest(operationOptions: RequestResponseOperationOptions) async throws
    -> MqttRequestResponse
  {
    return try await clientCore.submitRequest(operationOptions: operationOptions)
  }

  /// Creates a stream operation, throws CRTError if the creation failed. Streaming operations "listen" to a specific kind of service event and invoke handlers every time
  /// one is received. You would need call open() on the operation to start the stream.
  ///
  /// - Parameters:
  ///     - streamOptions: Configuration options for streaming operations
  /// - Returns: StreamingOperation, you would need call open() on the operation to start the stream
  /// - Throws: CommonRuntimeError.crtError if creation failed
  public func createStream(streamOptions: StreamingOperationOptions) throws -> StreamingOperation {
    return try clientCore.createStream(streamOptions: streamOptions)
  }

  deinit {
    self.clientCore.close()
  }

}
