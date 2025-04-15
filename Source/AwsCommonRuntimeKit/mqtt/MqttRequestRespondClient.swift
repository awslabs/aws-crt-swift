///  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
///  SPDX-License-Identifier: Apache-2.0.
import AwsCMqtt
import LibNative
import Foundation

/**
 * The type of change to the state of a streaming operation subscription
 */
public enum SubscriptionStatusEventType {
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

/**
 * An event that describes a change in subscription status for a streaming operation.
 */
 
public struct SubscriptionStatusEvent {
    let event: SubscriptionStatusEventType
    let errorCode: Int
}

/**
 * An event that describes an incoming publish message received on a streaming operation.
 *
 * TODO: Igor have updated the events for IoT Command. Need update later
 */
public struct IncomingPublishEvent {

    /// The payload of the publish message in a byte buffer format
    let payload: Data

    /// The topic associated with this PUBLISH packet.
    let topic: String
    
    /// TODO: More options for IoT Command changes
    /// ...
}

/// Encapsulates a response to an AWS IoT Core MQTT-based service request
public struct MqttRequestResponseResponse {
    let topic: String
    let payload: Data
}

public struct ResponsePath {
    let topic: String
    let correlationTokenJsonPath: [String]
}

/// Generic configuration options for request response operation
public struct RequestResponseOperationOptions: CStruct {
    let subscriptionTopicFilters: [String]
    let responsePaths: [ResponsePath]?
    let topic: String
    let payload: Data
    let correlationToken: [String]?
    
    public init () {
        // TODO: INIT THE MEMBERS
        self.subscriptionTopicFilters = []
        self.responsePaths = []
        self.topic = ""
        self.payload = Data()
        self.correlationToken = nil
    }

    typealias RawType = aws_mqtt_request_operation_options
    func withCStruct<Result>(_ body: (RawType) -> Result) -> Result {
        // TODO: convert into aws_mqtt_request_operation_options
        var options = aws_mqtt_request_operation_options()
        return body(options)
    }

}

// Place holder for
public typealias SubscriptionStatusEventHandler = (SubscriptionStatusEvent) async -> Void
public typealias IncomingPublishEventHandler = (IncomingPublishEvent) async -> Void

/// Generic configuration options for streaming operations
public struct StreamingOperationOptions: CStruct {
    let subscriptionStatusEventHandler: SubscriptionStatusEventHandler
    let incomingPublishEventHandler: IncomingPublishEventHandler
    let topicFilter: String

    public init () {
        // TODO: INIT THE MEMBERS
    }

    typealias RawType = aws_mqtt_streaming_operation_options
    func withCStruct<Result>(_ body: (RawType) -> Result) -> Result {
        // TODO: convert into aws_mqtt_request_operation_options
        var options = aws_mqtt_streaming_operation_options()
        return body(options)
    }
    
}

/**
 * A streaming operation is automatically closed (and an MQTT unsubscribe triggered) when its
 * destructor is invoked.
 */
public class StreamingOperation {
    fileprivate var rawValue: UnsafeMutablePointer<aws_mqtt_rr_client_operation>?

    public init () {
        // TODO: INIT THE MEMBERS
        self.rawValue = nil
    }
    
    /**
     * Opens a streaming operation by making the appropriate MQTT subscription with the broker.
     */
    public func open() {
        // TODO:
    }

    deinit{
        // TODO: close the oepration
    }
}

public struct MqttRequestResponseClientOptions: CStruct {

    let maxRequestResponseSubscription: Int
    let maxStreamingSubscription: Int
    let operationTimeout: TimeInterval?
    
    public init () {
        // TODO: INIT THE MEMBERS, it is set to random value for compile
        self.maxRequestResponseSubscription = 10
        self.maxStreamingSubscription = 10
        self.operationTimeout = TimeInterval(60)
    }

    typealias RawType = aws_mqtt_request_response_client_options
    func withCStruct<Result>(_ body: (RawType) -> Result) -> Result {
        // TODO: convert into aws_mqtt_request_response_client_options
        let options = aws_mqtt_request_response_client_options()
        return body(options)
    }

}

public class MqttRequestRespondClient {
    fileprivate var rawValue: UnsafeMutablePointer<aws_mqtt_request_response_client>?
    fileprivate let rwlock = ReadWriteLock()
    
    public static func newFromMqtt5Client(
        mqtt5Client: Mqtt5Client,
        options: MqttRequestResponseClientOptions = MqttRequestResponseClientOptions()) throws -> MqttRequestRespondClient {
            return MqttRequestRespondClient(mqttClient: mqtt5Client, options: options)
    }
    
    internal init(mqttClient: Mqtt5Client, options: MqttRequestResponseClientOptions) {
        // TODO: create request respond client from mqtt5 client
    }
    
    /// submit a request responds operation, throws CRTError if the operation failed
    public func submitRequest(operationOptions: RequestResponseOperationOptions) async throws -> MqttRequestResponseResponse {
        // TODO: sumibt request
        return MqttRequestResponseResponse(topic: "", payload: Data())
    }
    
    /// create a stream operation, throws CRTError if the creation failed. You would need call open() on the operation to start the stream
    public func createStream(streamOptions: StreamingOperationOptions) async throws -> StreamingOperation {
        // TODO: create streamming operation
        return StreamingOperation()
    }
    
}
