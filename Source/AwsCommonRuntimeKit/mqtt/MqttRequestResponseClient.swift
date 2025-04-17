///  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
///  SPDX-License-Identifier: Apache-2.0.
import AwsCMqtt
import LibNative
import Foundation

/**
 * The type of change to the state of a streaming operation subscription
 */
public enum SubscriptionStatusEventType: Sendable {
    /**
     * The streaming operation is successfully subscribed to its topic (filter)
     */
    case established

    /**
     * The streaming operation has temporarily lost its subscription to its topic (filter)
     */
    case lost

    /**
     * The streaming operation has entered a terminal state where it has given up trying to subscribe
     * to its topic (filter).  This is always due to user error (bad topic filter or IoT Core permission
     * policy).
     */
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

// TODO: Igor has updated the events for IoT Command. Need update later
/// An event that describes an incoming publish message received on a streaming operation.
public struct IncomingPublishEvent: Sendable {

    /// The payload of the publish message in a byte buffer format
    let payload: Data

    /// The topic associated with this PUBLISH packet.
    let topic: String
    
    // TODO: More options for IoT Command changes
}

/// Function signature of a SubscriptionStatusEvent event handler
public typealias SubscriptionStatusEventHandler = @Sendable (SubscriptionStatusEvent) async -> Void

/// Function signature of an IncomingPublishEvent event handler
public typealias IncomingPublishEventHandler = @Sendable (IncomingPublishEvent) async -> Void

/// Encapsulates a response to an AWS IoT Core MQTT-based service request
public struct MqttRequestResponseResponse {
    let topic: String
    let payload: Data
    let error: CRTError?
    
    public init(topic: String, payload: Data, error: CRTError? = nil) {
        self.topic = topic
        self.payload = payload
        self.error = error
    }
}

/// A response path is a pair of values - MQTT topic and a JSON path - that describe where a response to
/// an MQTT-based request may arrive.  For a given request type, there may be multiple response paths and each
/// one is associated with a separate JSON schema for the response body.
public struct ResponsePath {
    let topic: String
    let correlationTokenJsonPath: String
}

/// Configuration options for request response operation
public struct RequestResponseOperationOptions: CStruct {
    let subscriptionTopicFilters: [String]
    let responsePaths: [ResponsePath]
    let topic: String
    let payload: Data
    let correlationToken: String?
    
    public init(subscriptionTopicFilters: [String], responsePaths: [ResponsePath], topic: String, payload: Data, correlationToken: String?) {
        self.subscriptionTopicFilters = subscriptionTopicFilters
        self.responsePaths = responsePaths
        self.topic = topic
        self.payload = payload
        self.correlationToken = correlationToken
    }

    typealias RawType = aws_mqtt_request_operation_options
    func withCStruct<Result>(_ body: (RawType) -> Result) -> Result {
        // TODO: convert into aws_mqtt_request_operation_options
        var options = aws_mqtt_request_operation_options()
        return body(options)
    }

}

/// Configuration options for streaming operations
public struct StreamingOperationOptions: CStruct, Sendable {
    let subscriptionStatusEventHandler: SubscriptionStatusEventHandler
    let incomingPublishEventHandler: IncomingPublishEventHandler
    let topicFilter: String

    public init () {
        // TODO: INIT THE MEMBERS
        self.subscriptionStatusEventHandler = {_ in return;}
        self.incomingPublishEventHandler = {_ in return;}
        self.topicFilter = ""
    }

    typealias RawType = aws_mqtt_streaming_operation_options
    func withCStruct<Result>(_ body: (RawType) -> Result) -> Result {
        // TODO: convert into aws_mqtt_request_operation_options
        let options = aws_mqtt_streaming_operation_options()
        return body(options)
    }
    
}

/**
 * A streaming operation is automatically closed (and an MQTT unsubscribe triggered) when its
 * destructor is invoked.
 */
public class StreamingOperation {
    fileprivate var rawValue: OpaquePointer? // <aws_mqtt_rr_client_operation>?

    public init () {
        // TODO: INIT THE MEMBERS
        self.rawValue = nil
    }
    
    /// Opens a streaming operation by making the appropriate MQTT subscription with the broker.
    public func open() {
        // TODO: open the stream
    }

    deinit{
        // TODO: close the oepration
    }
}

// TODO: Choose a proper default value for client options
// We can't mutate this class after initialization. Swift can not verify the sendability due to the class is non-final,
// so mark it unchecked Sendable
/// Request-response client configuration options
public class MqttRequestResponseClientOptions: CStructWithUserData, @unchecked Sendable{

    /// Maximum number of subscriptions that the client will concurrently use for request-response operations. Default to 3.
    public let maxRequestResponseSubscription: Int
    
    /// Maximum number of subscriptions that the client will concurrently use for streaming operations Default to 0.
    public let maxStreamingSubscription: Int
    
    /// Duration, in seconds, that a request-response operation will wait for completion before giving up. Default to 5 seconds.
    public let operationTimeout: TimeInterval
    
    public init(maxRequestResponseSubscription: Int = 3, maxStreamingSubscription: Int = 2, operationTimeout: TimeInterval = 5) {
        self.maxStreamingSubscription = maxStreamingSubscription
        self.maxRequestResponseSubscription = maxRequestResponseSubscription
        self.operationTimeout = operationTimeout
    }
    
    func validateConversionToNative() throws {
        do {
            _ = try self.operationTimeout.secondUInt32()
        } catch {
            throw CommonRunTimeError.crtError(CRTError(code: AWS_ERROR_INVALID_ARGUMENT.rawValue,
                                                       context: "Invalid operationTimeout value"))
        }
    }
    
    typealias RawType = aws_mqtt_request_response_client_options
    func withCStruct<Result>(userData: UnsafeMutableRawPointer?, _ body: (aws_mqtt_request_response_client_options) -> Result) -> Result {
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

internal func MqttRRClientTerminationCallback(_ userData: UnsafeMutableRawPointer?) {
    // Termination callback. This is triggered when the native client is terminated.
    // It is safe to release the request response client at this point.
    // `takeRetainedValue()` would release the client reference. ONLY DO IT AFTER YOU NEED RELEASE THE CLIENT
    _ = Unmanaged<MqttRequestResponseClientCore>.fromOpaque(userData!).takeRetainedValue()
}

internal class MqttRequestResponseClientCore {
    fileprivate var rawValue: OpaquePointer? // aws_mqtt_request_response_client
    
    internal init(mqttClient: Mqtt5Client, options: MqttRequestResponseClientOptions) throws {
        guard let rawValue = (options.withCPointer(
            userData: Unmanaged<MqttRequestResponseClientCore>.passRetained(self).toOpaque()) { optionsPointer in
                return aws_mqtt_request_response_client_new_from_mqtt5_client(
                    allocator, mqttClient.clientCore.rawValue, optionsPointer)
            }) else {
            // failed to create client, release the callback core
            Unmanaged<MqttRequestResponseClientCore>.passUnretained(self).release()
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        self.rawValue = rawValue
        
    }
    
    /// submit a request responds operation, throws CRTError if the operation failed
    public func submitRequest(operationOptions: RequestResponseOperationOptions) async throws -> MqttRequestResponseResponse {
        // TODO: sumibt request
        return MqttRequestResponseResponse(topic: "", payload: Data())
    }
    
    /// create a stream operation, throws CRTError if the creation failed. You would need call open() on the operation to start the stream
    public func createStream(streamOptions: StreamingOperationOptions) throws -> StreamingOperation {
        // TODO: create streamming operation
        return StreamingOperation()
    }
    
    /// release the request response client. You must not use the client after call `close()`.
    public func close() {
        aws_mqtt_request_response_client_release(self.rawValue)
        self.rawValue = nil
    }
    
}

public class MqttRequestResponseClient {
    fileprivate var clientCore: MqttRequestResponseClientCore
    
    /// Creates a new request-response client using an MQTT5 client for protocol transport
    ///
    /// - Parameters:
    ///     - mqtt5Client: protocolClient MQTT client to use for transport
    ///     - options: request-response client configuration options
    ///
    /// - Returns:return a new MqttRequestResponseClient if success
    ///
    /// - Throws: CommonRuntimeError.crtError if creation failed
    public static func newFromMqtt5Client(
        mqtt5Client: Mqtt5Client,
        options: MqttRequestResponseClientOptions? = nil) throws -> MqttRequestResponseClient {
            return try MqttRequestResponseClient(mqttClient: mqtt5Client, options: options ?? MqttRequestResponseClientOptions())
    }
    
    internal init(mqttClient: Mqtt5Client, options: MqttRequestResponseClientOptions) throws {
        clientCore = try MqttRequestResponseClientCore(mqttClient: mqttClient, options: options)
    }
    
    /// Submit a request responds operation, throws CRTError if the operation failed
    ///
    /// - Parameters:
    ///     - operationOptions: configuration options for request response operation
    /// - Returns:
    ///     - MqttRequestResponseResponse
    /// - Throws:CommonRuntimeError.crtError if submit failed
    public func submitRequest(operationOptions: RequestResponseOperationOptions) async throws -> MqttRequestResponseResponse {
        return try await clientCore.submitRequest(operationOptions: operationOptions)
    }
    
    /// Create a stream operation, throws CRTError if the creation failed. You would need call open() on the operation to start the stream
    /// - Parameters:
    ///     - streamOptions: Configuration options for streaming operations
    /// - Returns:
    ///     - StreamingOperation
    /// - Throws:CommonRuntimeError.crtError if creation failed
    public func createStream(streamOptions: StreamingOperationOptions) throws -> StreamingOperation {
        return try clientCore.createStream(streamOptions: streamOptions)
    }
    
    deinit{
        self.clientCore.close()
    }
    
}
