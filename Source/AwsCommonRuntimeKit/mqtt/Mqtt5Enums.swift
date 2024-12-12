///  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
///  SPDX-License-Identifier: Apache-2.0.

import AwsCMqtt

/// MQTT message delivery quality of service.
/// Enum values match `MQTT5 spec <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901234>`__ encoding values.
public enum QoS {

    /// The message is delivered according to the capabilities of the underlying network. No response is sent by the
    /// receiver and no retry is performed by the sender. The message arrives at the receiver either once or not at all.
    case atMostOnce

    /// A level of service that ensures that the message arrives at the receiver at least once.
    case atLeastOnce

    /// A level of service that ensures that the message arrives at the receiver exactly once.
    /// Note that this client does not currently support QoS 2 as of (March 2024)
    case exactlyOnce

}

extension QoS {
    /// Returns the native representation of the Swift enum
    var rawValue: aws_mqtt5_qos {
        switch self {
        case .atMostOnce: return AWS_MQTT5_QOS_AT_MOST_ONCE
        case .atLeastOnce: return AWS_MQTT5_QOS_AT_LEAST_ONCE
        case .exactlyOnce: return AWS_MQTT5_QOS_EXACTLY_ONCE
        }
    }

    /// Initializes Swift enum from native representation
    init(_ cEnum: aws_mqtt5_qos) {
        switch cEnum {
        case AWS_MQTT5_QOS_AT_MOST_ONCE:
            self = .atMostOnce
        case AWS_MQTT5_QOS_AT_LEAST_ONCE:
            self = .atLeastOnce
        case AWS_MQTT5_QOS_EXACTLY_ONCE:
            self = .exactlyOnce
        default:
            fatalError("Unknown QoS Value")
        }
    }
}

/// Server return code for connect attempts.
/// Enum values match `MQTT5 spec <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901079>`__ encoding values.
public enum ConnectReasonCode: Int {

    /// Returned when the connection is accepted.
    case success = 0

    /// Returned when the server has a failure but does not want to specify a reason or none
    /// of the other reason codes apply.
    case unspecifiedError = 128

    /// Returned when data in the CONNECT packet could not be correctly parsed by the server.
    case malformedPacket = 129

    /// Returned when data in the CONNECT packet does not conform to the MQTT5 specification requirements.
    case protocolError = 130

    /// Returned when the CONNECT packet is valid but was not accepted by the server.
    case implementationSpecificError = 131

    /// Returned when the server does not support MQTT5 protocol version specified in the connection.
    case unsupportedProtocolVersion = 132

    /// Returned when the client identifier in the CONNECT packet is a valid string but not one that
    /// is allowed on the server.
    case clientIdentifierNotValid = 133

    /// Returned when the server does not accept the username and/or password specified by the client
    /// in the connection packet.
    case badUsernameOrPassword = 134

    /// Returned when the client is not authorized to connect to the server.
    case notAuthorized = 135

    /// Returned when the MQTT5 server is not available.
    case serverUnavailable = 136

    /// Returned when the server is too busy to make a connection. It is recommended that the client try again later.
    case serverBusy = 137

    /// Returned when the client has been banned by the server.
    case banned = 138

    /// Returned when the authentication method used in the connection is either not supported on the server or it does
    /// not match the authentication method currently in use in the CONNECT packet.
    case badAuthenticationMethod = 140

    /// Returned when the Will topic name sent in the CONNECT packet is correctly formed, but is not accepted by
    /// the server.
    case topicNameInvalid = 144

    /// Returned when the CONNECT packet exceeded the maximum permissible size on the server.
    case packetTooLarge = 149

    /// Returned when the quota limits set on the server have been met and/or exceeded.
    case quotaExceeded = 151

    /// Returned when the Will payload in the CONNECT packet does not match the specified payload format indicator.
    case payloadFormatInvalid = 153

    /// Returned when the server does not retain messages but the CONNECT packet on the client had Will retain enabled.
    case retainNotSupported = 154

    /// Returned when the server does not support the QOS setting set in the Will QOS in the CONNECT packet.
    case qosNotSupported = 155

    /// Returned when the server is telling the client to temporarily use another server instead of the one they
    /// are trying to connect to.
    case useAnotherServer = 156

    /// Returned when the server is telling the client to permanently use another server instead of the one they
    /// are trying to connect to.
    case serverMoved = 157

    /// Returned when the server connection rate limit has been exceeded.
    case connectionRateExceeded = 159

}

/// Reason code inside DISCONNECT packets.  Helps determine why a connection was terminated.
/// Enum values match `MQTT5 spec <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901208>`__ encoding values.
public enum DisconnectReasonCode: Int {

    /// Returned when the remote endpoint wishes to disconnect normally. Will not trigger the publish of a Will message if a
    /// Will message was configured on the connection.
    /// May be sent by the client or server.
    case normalDisconnection = 0

    /// Returns when the client wants to disconnect but requires that the server publish the Will message configured
    /// on the connection.
    /// May only be sent by the client.
    case disconnectWithWillMessage = 4

    /// Returned when the connection was closed but the sender does not want to specify a reason or none
    /// of the other reason codes apply.
    /// May be sent by the client or the server.
    case unspecifiedError = 128

    /// Indicates the remote endpoint received a packet that does not conform to the MQTT specification.
    /// May be sent by the client or the server.
    case malformedPacket = 129

    /// Returned when an unexpected or out-of-order packet was received by the remote endpoint.
    /// May be sent by the client or the server.
    case protocolError = 130

    /// Returned when a valid packet was received by the remote endpoint, but could not be processed by the current implementation.
    /// May be sent by the client or the server.
    case implementationSpecificError = 131

    /// Returned when the remote endpoint received a packet that represented an operation that was not authorized within
    /// the current connection.
    /// May only be sent by the server.
    case notAuthorized = 135

    /// Returned when the server is busy and cannot continue processing packets from the client.
    /// May only be sent by the server.
    case serverBusy = 137

    /// Returned when the server is shutting down.
    /// May only be sent by the server.
    case serverShuttingDown = 139

    /// Returned when the server closes the connection because no packet from the client has been received in
    /// 1.5 times the KeepAlive time set when the connection was established.
    /// May only be sent by the server.
    case keepAliveTimout = 141

    /// Returned when the server has established another connection with the same client ID as a client's current
    /// connection, causing the current client to become disconnected.
    /// May only be sent by the server.
    case sessionTakenOver = 142

    /// Returned when the topic filter name is correctly formed but not accepted by the server.
    /// May only be sent by the server.
    case topicFilterInvalid = 143

    /// Returned when topic name is correctly formed, but is not accepted.
    /// May be sent by the client or the server.
    case topicNameInvalid = 144

    /// Returned when the remote endpoint reached a state where there were more in-progress QoS1+ publishes then the
    /// limit it established for itself when the connection was opened.
    /// May be sent by the client or the server.
    case receiveMaximumExceeded = 147

    /// Returned when the remote endpoint receives a PUBLISH packet that contained a topic alias greater than the
    /// maximum topic alias limit that it established for itself when the connection was opened.
    /// May be sent by the client or the server.
    case topicAliasInvalid = 148

    /// Returned when the remote endpoint received a packet whose size was greater than the maximum packet size limit
    /// it established for itself when the connection was opened.
    /// May be sent by the client or the server.
    case packetTooLarge = 149

    /// Returned when the remote endpoint's incoming data rate was too high.
    /// May be sent by the client or the server.
    case messageRateTooHigh = 150

    /// Returned when an internal quota of the remote endpoint was exceeded.
    /// May be sent by the client or the server.
    case quotaExceeded = 151

    /// Returned when the connection was closed due to an administrative action.
    /// May be sent by the client or the server.
    case administrativeAction = 152

    /// Returned when the remote endpoint received a packet where payload format did not match the format specified
    /// by the payload format indicator.
    /// May be sent by the client or the server.
    case payloadFormatInvalid = 153

    /// Returned when the server does not support retained messages.
    /// May only be sent by the server.
    case retainNotSupported = 154

    /// Returned when the client sends a QoS that is greater than the maximum QoS established when the connection was
    /// opened.
    /// May only be sent by the server.
    case qosNotSupported = 155

    /// Returned by the server to tell the client to temporarily use a different server.
    /// May only be sent by the server.
    case useAnotherServer = 156

    /// Returned by the server to tell the client to permanently use a different server.
    /// May only be sent by the server.
    case serverMoved = 157

    /// Returned by the server to tell the client that shared subscriptions are not supported on the server.
    /// May only be sent by the server.
    case sharedSubscriptionsNotSupported = 158

    /// Returned when the server disconnects the client due to the connection rate being too high.
    /// May only be sent by the server.
    case connectionRateExceeded = 159

    /// Returned by the server when the maximum connection time authorized for the connection was exceeded.
    /// May only be sent by the server.
    case maximumConnectTime = 160

    /// Returned by the server when it received a SUBSCRIBE packet with a subscription identifier, but the server does
    /// not support subscription identifiers.
    /// May only be sent by the server.
    case subscriptionIdentifiersNotSupported = 161

    /// Returned by the server when it received a SUBSCRIBE packet with a wildcard topic filter, but the server does
    /// not support wildcard topic filters.
    /// May only be sent by the server.
    case wildcardSubscriptionsNotSupported = 162
}

/// Reason code inside PUBACK packets that indicates the result of the associated PUBLISH request.
/// Enum values match `MQTT5 spec <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901124>`__ encoding values.
public enum PubackReasonCode: Int {

    /// Returned when the (QoS 1) publish was accepted by the recipient.
    /// May be sent by the client or the server.
    case success = 0

    /// Returned when the (QoS 1) publish was accepted but there were no matching subscribers.
    /// May only be sent by the server.
    case noMatchingSubscribers = 16

    /// Returned when the (QoS 1) publish was not accepted and the receiver does not want to specify a reason or none
    /// of the other reason codes apply.
    /// May be sent by the client or the server.
    case unspecifiedError = 128

    /// Returned when the (QoS 1) publish was valid but the receiver was not willing to accept it.
    /// May be sent by the client or the server.
    case implementationSpecificError = 131

    /// Returned when the (QoS 1) publish was not authorized by the receiver.
    /// May be sent by the client or the server.
    case notAuthorized = 135

    /// Returned when the topic name was valid but the receiver was not willing to accept it.
    /// May be sent by the client or the server.
    case topicNameInvalid = 144

    /// Returned when the packet identifier used in the associated PUBLISH was already in use.
    /// This can indicate a mismatch in the session state between client and server.
    /// May be sent by the client or the server.
    case packetIdentifierInUse = 145

    /// Returned when the associated PUBLISH failed because an internal quota on the recipient was exceeded.
    /// May be sent by the client or the server.
    case quotaExceeded = 151

    /// Returned when the PUBLISH packet's payload format did not match its payload format indicator property.
    /// May be sent by the client or the server.
    case payloadFormatInvalid = 153
}

/// Reason code inside SUBACK packet payloads.
/// Enum values match `MQTT5 spec <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901178>`__ encoding values.
/// This will only be sent by the server and not the client.
public enum SubackReasonCode: Int {

    /// Returned when the subscription was accepted and the maximum QoS sent will be QoS 0.
    case grantedQos0 = 0

    /// Returned when the subscription was accepted and the maximum QoS sent will be QoS 1.
    case grantedQos1 = 1

    /// Returned when the subscription was accepted and the maximum QoS sent will be QoS 2.
    case grantedQos2 = 2

    /// Returned when the connection was closed but the sender does not want to specify a reason or none
    /// of the other reason codes apply.
    case unspecifiedError = 128

    /// Returned when the subscription was valid but the server did not accept it.
    case implementationSpecificError = 131

    /// Returned when the client was not authorized to make the subscription on the server.
    case notAuthorized = 135

    /// Returned when the subscription topic filter was correctly formed but not allowed for the client.
    case topicFilterInvalid = 143

    /// Returned when the packet identifier was already in use on the server.
    case packetIdentifierInUse = 145

    /// Returned when a subscribe-related quota set on the server was exceeded.
    case quotaExceeded = 151

    /// Returned when the subscription's topic filter was a shared subscription and the server does not support
    /// shared subscriptions.
    case sharedSubscriptionsNotSupported = 158

    /// Returned when the SUBSCRIBE packet contained a subscription identifier and the server does not support
    /// subscription identifiers.
    case subscriptionIdentifiersNotSupported = 161

    /// Returned when the subscription's topic filter contains a wildcard but the server does not support
    /// wildcard subscriptions.
    case wildcardSubscriptionsNotSupported = 162
}

/// Reason codes inside UNSUBACK packet payloads that specify the results for each topic filter in the associated
/// UNSUBSCRIBE packet.
/// Enum values match `MQTT5 spec <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901194>`__ encoding values.
public enum UnsubackReasonCode: Int {

    /// Returned when the unsubscribe was successful and the client is no longer subscribed to the topic filter on the server.
    case success = 0

    /// Returned when the topic filter did not match one of the client's existing topic filters on the server.
    case noSubscriptionExisted = 17

    /// Returned when the unsubscribe of the topic filter was not accepted and the server does not want to specify a
    /// reason or none of the other reason codes apply.
    case unspecifiedError = 128

    /// Returned when the topic filter was valid but the server does not accept an unsubscribe for it.
    case implementationSpecificError = 131

    /// Returned when the client was not authorized to unsubscribe from that topic filter on the server.
    case notAuthorized = 135

    /// Returned when the topic filter was correctly formed but is not allowed for the client on the server.
    case topicFilterInvalid = 143

    /// Returned when the packet identifier was already in use on the server.
    case packetIdentifierInUse = 145
}

/// Controls how the mqtt client should behave with respect to MQTT sessions.
public enum ClientSessionBehaviorType {

    /// Default client session behavior. Maps to CLEAN.
    case `default`

    /// Always ask for a clean session when connecting
    case clean

    /// Always attempt to rejoin an existing session after an initial connection success.
    /// Session rejoin requires an appropriate non-zero session expiry interval in the client's CONNECT options.
    case rejoinPostSuccess

    /// Always attempt to rejoin an existing session.  Since the client does not support durable session persistence,
    /// this option is not guaranteed to be spec compliant because any unacknowledged qos1 publishes (which are
    /// part of the client session state) will not be present on the initial connection.  Until we support
    /// durable session resumption, this option is technically spec-breaking, but useful.
    /// Always rejoin requires an appropriate non-zero session expiry interval in the client's CONNECT options.
    case rejoinAlways
}

extension ClientSessionBehaviorType {
    /// Returns the native representation of the Swift enum
    var rawValue: aws_mqtt5_client_session_behavior_type {
        switch self {
        case .default: return AWS_MQTT5_CSBT_DEFAULT
        case .clean: return AWS_MQTT5_CSBT_CLEAN
        case .rejoinPostSuccess: return AWS_MQTT5_CSBT_REJOIN_POST_SUCCESS
        case .rejoinAlways: return AWS_MQTT5_CSBT_REJOIN_ALWAYS
        }
    }
}

/// Additional controls for client behavior with respect to operation validation and flow control; these checks
/// go beyond the MQTT5 spec to respect limits of specific MQTT brokers.
public enum ExtendedValidationAndFlowControlOptions {

    /// Do not do any additional validation or flow control
    case none

    /// Apply additional client-side validation and operational flow control that respects the
    /// default AWS IoT Core limits.
    /// Currently applies the following additional validation:
    /// * No more than 8 subscriptions per SUBSCRIBE packet
    /// * Topics and topic filters have a maximum of 7 slashes (8 segments), not counting any AWS rules prefix
    /// * Topics must be 256 bytes or less in length
    /// * Client id must be 128 or less bytes in length
    /// Also applies the following flow control:
    /// * Outbound throughput throttled to 512KB/s
    /// * Outbound publish TPS throttled to 100
    case awsIotCoreDefaults
}

extension ExtendedValidationAndFlowControlOptions {
    /// Returns the native representation of the Swift enum
    var rawValue: aws_mqtt5_extended_validation_and_flow_control_options {
        switch self {
        case .none:  return AWS_MQTT5_EVAFCO_NONE
        case .awsIotCoreDefaults:  return AWS_MQTT5_EVAFCO_AWS_IOT_CORE_DEFAULTS
        }
    }
}

/// Controls how disconnects affect the queued and in-progress operations tracked by the client.  Also controls
/// how operations are handled while the client is not connected.  In particular, if the client is not connected,
/// then any operation that would be failed on disconnect (according to these rules) will be rejected.
public enum ClientOperationQueueBehaviorType {

    /// Default client operation queue behavior. Maps to FAIL_QOS0_PUBLISH_ON_DISCONNECT.
    case `default`

    /// Re-queues QoS 1+ publishes on disconnect; un-acked publishes go to the front while unprocessed publishes stay
    /// in place.  All other operations (QoS 0 publishes, subscribe, unsubscribe) are failed.
    case failNonQos1PublishOnDisconnect

    /// QoS 0 publishes that are not complete at the time of disconnection are failed.  Un-acked QoS 1+ publishes are
    /// re-queued at the head of the line for immediate retransmission on a session resumption.  All other operations
    /// are requeued in original order behind any retransmissions.
    case failQos0PublishOnDisconnect

    /// All operations that are not complete at the time of disconnection are failed, except operations that
    /// the MQTT5 spec requires to be retransmitted (un-acked QoS1+ publishes).
    case failAllOnDisconnect
}

extension ClientOperationQueueBehaviorType {
    /// Returns the native representation of the Swift enum
    var rawValue: aws_mqtt5_client_operation_queue_behavior_type {
        switch self {
        case .default: return AWS_MQTT5_COQBT_DEFAULT
        case .failNonQos1PublishOnDisconnect:  return AWS_MQTT5_COQBT_FAIL_NON_QOS1_PUBLISH_ON_DISCONNECT
        case .failQos0PublishOnDisconnect:  return AWS_MQTT5_COQBT_FAIL_QOS0_PUBLISH_ON_DISCONNECT
        case .failAllOnDisconnect:  return AWS_MQTT5_COQBT_FAIL_ALL_ON_DISCONNECT
        }
    }
}

/// Optional property describing a PUBLISH payload's format.
/// Enum values match `MQTT5 spec <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901111>`__ encoding values.
public enum PayloadFormatIndicator {

    /// The payload is arbitrary binary data
    case bytes

    /// The payload is a well-formed utf-8 string value.
    case utf8
}

extension PayloadFormatIndicator {
    var rawValue: aws_mqtt5_payload_format_indicator {
        switch self {
        case .bytes: return AWS_MQTT5_PFI_BYTES
        case .utf8: return AWS_MQTT5_PFI_UTF8
        }
    }

    /// Initializes Swift enum from native representation
    init(_ cEnum: aws_mqtt5_payload_format_indicator) {
        switch cEnum {
        case AWS_MQTT5_PFI_BYTES:
            self = .bytes
        case AWS_MQTT5_PFI_UTF8:
            self = .utf8
        default:
            fatalError("Unknown QoS Value")
        }
    }
}

/// Configures how retained messages should be handled when subscribing with a topic filter that matches topics with
/// associated retained messages.
/// Enum values match `MQTT5 spec <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901169>`_ encoding values.
public enum RetainHandlingType {

    /// The server should always send all retained messages on topics that match a subscription's filter.
    case sendOnSubscribe

    /// The server should send retained messages on topics that match the subscription's filter, but only for the
    /// first matching subscription, per session.
    case sendOnSubscribeIfNew

    /// Subscriptions must not trigger any retained message publishes from the server.
    case dontSend
}

extension RetainHandlingType {
    /// Returns the native representation of the Swift enum
    var rawValue: aws_mqtt5_retain_handling_type {
        switch self {
        case .sendOnSubscribe: return AWS_MQTT5_RHT_SEND_ON_SUBSCRIBE
        case .sendOnSubscribeIfNew: return AWS_MQTT5_RHT_SEND_ON_SUBSCRIBE_IF_NEW
        case .dontSend: return AWS_MQTT5_RHT_DONT_SEND
        }
    }
}

/// An enumeration that controls how the client applies topic aliasing to outbound publish packets.
/// Topic alias behavior is described in `MQTT5 Topic Aliasing <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901113>`_
public enum OutboundTopicAliasBehaviorType {
    /// Maps to Disabled.  This keeps the client from being broken (by default) if the broker
    /// topic aliasing implementation has a problem.
    case defaultBehavior

    ///  Outbound aliasing is the user's responsibility.  Client will cache and use
    ///  previously-established aliases if they fall within the negotiated limits of the connection.
    ///  The user must still always submit a full topic in their publishes because disconnections disrupt
    ///  topic alias mappings unpredictably.  The client will properly use a requested alias when the most-recently-seen
    ///  binding for a topic alias value matches the alias and topic in the publish packet.
    case manual

    /// (Recommended) The client will ignore any user-specified topic aliasing and instead use an LRU cache to drive
    ///  alias usage.
    case lru

    /// Completely disable outbound topic aliasing.
    case disabled
}

extension OutboundTopicAliasBehaviorType {
    /// Returns the native representation of the Swift enum
    var rawValue: aws_mqtt5_client_outbound_topic_alias_behavior_type {
        switch self {
        case .defaultBehavior: return AWS_MQTT5_COTABT_DEFAULT
        case .manual: return AWS_MQTT5_COTABT_MANUAL
        case .lru: return AWS_MQTT5_COTABT_LRU
        case .disabled: return AWS_MQTT5_COTABT_DISABLED
        }
    }
}

/// An enumeration that controls whether or not the client allows the broker to send publishes that use topic
/// aliasing.
/// Topic alias behavior is described in `MQTT5 Topic Aliasing <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901113>`_
public enum InboundTopicAliasBehaviorType {

    /// Maps to Disabled.  This keeps the client from being broken (by default) if the broker
    /// topic aliasing implementation has a problem.
    case `default`

    /// Allow the server to send PUBLISH packets to the client that use topic aliasing
    case enabled

    /// Forbid the server from sending PUBLISH packets to the client that use topic aliasing
    case disabled
}

extension InboundTopicAliasBehaviorType {
    /// Returns the native representation of the Swift enum
    var rawValue: aws_mqtt5_client_inbound_topic_alias_behavior_type {
        switch self {
        case .default: return AWS_MQTT5_CITABT_DEFAULT
        case .enabled: return AWS_MQTT5_CITABT_ENABLED
        case .disabled: return AWS_MQTT5_CITABT_DISABLED
        }
    }
}
