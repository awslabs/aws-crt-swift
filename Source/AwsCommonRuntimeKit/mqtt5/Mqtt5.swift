//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

// MQTT message delivery quality of service.
// Enum values match `MQTT5 spec <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901234>`__ encoding values.
public enum QoS {

    // The message is delivered according to the capabilities of the underlying network. No response is sent by the
    // receiver and no retry is performed by the sender. The message arrives at the receiver either once or not at all.
    case AT_MOST_ONCE = 0

    //A level of service that ensures that the message arrives at the receiver at least once.
    case AT_LEAST_ONCE = 1

    // A level of service that ensures that the message arrives at the receiver exactly once.
    // Note that this client does not currently support QoS 2 as of (March 2024)
    case EXACTLY_ONCE = 2
}

// Server return code for connect attempts.
// Enum values match `MQTT5 spec <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901079>`__ encoding values.
public enum ConnectReasonCode {

    // Returned when the connection is accepted.
    case SUCCESS = 0

    // Returned when the server has a failure but does not want to specify a reason or none
    // of the other reason codes apply.
    case UNSPECIFIED_ERROR = 128

    // Returned when data in the CONNECT packet could not be correctly parsed by the server.
    case MALFORMED_PACKET = 129

    // Returned when data in the CONNECT packet does not conform to the MQTT5 specification requirements.
    case PROTOCOL_ERROR = 130

    // Returned when the CONNECT packet is valid but was not accepted by the server.
    case IMPLEMENTATION_SPECIFIC_ERROR = 131

    // Returned when the server does not support MQTT5 protocol version specified in the connection.
    case UNSUPPORTED_PROTOCOL_VERSION = 132

    // Returned when the client identifier in the CONNECT packet is a valid string but not one that
    // is allowed on the server.
    case CLIENT_IDENTIFIER_NOT_VALID = 133

    // Returned when the server does not accept the username and/or password specified by the client
    // in the connection packet.
    case BAD_USERNAME_OR_PASSWORD = 134

    // Returned when the client is not authorized to connect to the server.
    case NOT_AUTHORIZED = 135

    // Returned when the MQTT5 server is not available.
    case SERVER_UNAVAILABLE = 136

    // Returned when the server is too busy to make a connection. It is recommended that the client try again later.
    case SERVER_BUSY = 137

    // Returned when the client has been banned by the server.
    case BANNED = 138

    // Returned when the authentication method used in the connection is either not supported on the server or it does
    // not match the authentication method currently in use in the CONNECT packet.
    case BAD_AUTHENTICATION_METHOD = 140

    // Returned when the Will topic name sent in the CONNECT packet is correctly formed, but is not accepted by
    // the server.
    case TOPIC_NAME_INVALID = 144

    // Returned when the CONNECT packet exceeded the maximum permissible size on the server.
    case PACKET_TOO_LARGE = 149

    // Returned when the quota limits set on the server have been met and/or exceeded.
    case QUOTA_EXCEEDED = 151

    // Returned when the Will payload in the CONNECT packet does not match the specified payload format indicator.
    case PAYLOAD_FORMAT_INVALID = 153

    // Returned when the server does not retain messages but the CONNECT packet on the client had Will retain enabled.
    case RETAIN_NOT_SUPPORTED = 154

    // Returned when the server does not support the QOS setting set in the Will QOS in the CONNECT packet.
    case QOS_NOT_SUPPORTED = 155

    // Returned when the server is telling the client to temporarily use another server instead of the one they
    // are trying to connect to.
    case USE_ANOTHER_SERVER = 156

    // Returned when the server is telling the client to permanently use another server instead of the one they
    // are trying to connect to.
    case SERVER_MOVED = 157

    // Returned when the server connection rate limit has been exceeded.
    case CONNECTION_RATE_EXCEEDED = 159
}

// Reason code inside DISCONNECT packets.  Helps determine why a connection was terminated.
// Enum values match `MQTT5 spec <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901208>`__ encoding values.
public enum DisconnectReasonCode {

    // Returned when the remote endpoint wishes to disconnect normally. Will not trigger the publish of a Will message if a
    // Will message was configured on the connection.
    // May be sent by the client or server.
    case NORMAL_DISCONNECTION = 0

    // Returns when the client wants to disconnect but requires that the server publish the Will message configured
    // on the connection.
    // May only be sent by the client.
    case DISCONNECT_WITH_WILL_MESSAGE = 4

    // Returned when the connection was closed but the sender does not want to specify a reason or none
    // of the other reason codes apply.
    // May be sent by the client or the server.
    case UNSPECIFIED_ERROR = 128

    // Indicates the remote endpoint received a packet that does not conform to the MQTT specification.
    // May be sent by the client or the server.
    case MALFORMED_PACKET = 129

    // Returned when an unexpected or out-of-order packet was received by the remote endpoint.
    // May be sent by the client or the server.
    case PROTOCOL_ERROR = 130

    // Returned when a valid packet was received by the remote endpoint, but could not be processed by the current implementation.
    // May be sent by the client or the server.
    case IMPLEMENTATION_SPECIFIC_ERROR = 131

    // Returned when the remote endpoint received a packet that represented an operation that was not authorized within
    // the current connection.
    // May only be sent by the server.
    case NOT_AUTHORIZED = 135

    // Returned when the server is busy and cannot continue processing packets from the client.
    // May only be sent by the server.
    case SERVER_BUSY = 137

    // Returned when the server is shutting down.
    // May only be sent by the server.
    case SERVER_SHUTTING_DOWN = 139

    // Returned when the server closes the connection because no packet from the client has been received in
    // 1.5 times the KeepAlive time set when the connection was established.
    // May only be sent by the server.
    case KEEP_ALIVE_TIMEOUT = 141

    // Returned when the server has established another connection with the same client ID as a client's current
    // connection, causing the current client to become disconnected.
    // May only be sent by the server.
    case SESSION_TAKEN_OVER = 142

    // Returned when the topic filter name is correctly formed but not accepted by the server.
    // May only be sent by the server.
    case TOPIC_FILTER_INVALID = 143

    // Returned when topic name is correctly formed, but is not accepted.
    // May be sent by the client or the server.
    case TOPIC_NAME_INVALID = 144

    // Returned when the remote endpoint reached a state where there were more in-progress QoS1+ publishes then the
    // limit it established for itself when the connection was opened.
    // May be sent by the client or the server.
    case RECEIVE_MAXIMUM_EXCEEDED = 147

    // Returned when the remote endpoint receives a PUBLISH packet that contained a topic alias greater than the
    // maximum topic alias limit that it established for itself when the connection was opened.
    // May be sent by the client or the server.
    case TOPIC_ALIAS_INVALID = 148

    // Returned when the remote endpoint received a packet whose size was greater than the maximum packet size limit
    // it established for itself when the connection was opened.
    // May be sent by the client or the server.
    case PACKET_TOO_LARGE = 149

    // Returned when the remote endpoint's incoming data rate was too high.
    // May be sent by the client or the server.
    case MESSAGE_RATE_TOO_HIGH = 150

    // Returned when an internal quota of the remote endpoint was exceeded.
    // May be sent by the client or the server.
    case QUOTA_EXCEEDED = 151

    // Returned when the connection was closed due to an administrative action.
    // May be sent by the client or the server.
    case ADMINISTRATIVE_ACTION = 152

    // Returned when the remote endpoint received a packet where payload format did not match the format specified
    // by the payload format indicator.
    // May be sent by the client or the server.
    case PAYLOAD_FORMAT_INVALID = 153

    // Returned when the server does not support retained messages.
    // May only be sent by the server.
    case RETAIN_NOT_SUPPORTED = 154

    // Returned when the client sends a QoS that is greater than the maximum QoS established when the connection was
    // opened.
    // May only be sent by the server.
    case QOS_NOT_SUPPORTED = 155

    // Returned by the server to tell the client to temporarily use a different server.
    // May only be sent by the server.
    case USE_ANOTHER_SERVER = 156

    // Returned by the server to tell the client to permanently use a different server.
    // May only be sent by the server.
    case SERVER_MOVED = 157

    // Returned by the server to tell the client that shared subscriptions are not supported on the server.
    // May only be sent by the server.
    case SHARED_SUBSCRIPTIONS_NOT_SUPPORTED = 158

    // Returned when the server disconnects the client due to the connection rate being too high.
    // May only be sent by the server.
    case CONNECTION_RATE_EXCEEDED = 159

    // Returned by the server when the maximum connection time authorized for the connection was exceeded.
    // May only be sent by the server.
    case MAXIMUM_CONNECT_TIME = 160

    // Returned by the server when it received a SUBSCRIBE packet with a subscription identifier, but the server does
    // not support subscription identifiers.
    // May only be sent by the server.
    case SUBSCRIPTION_IDENTIFIERS_NOT_SUPPORTED = 161

    // Returned by the server when it received a SUBSCRIBE packet with a wildcard topic filter, but the server does
    // not support wildcard topic filters.
    // May only be sent by the server.
    case WILDCARD_SUBSCRIPTIONS_NOT_SUPPORTED = 162
}

// Reason code inside PUBACK packets that indicates the result of the associated PUBLISH request.
// Enum values match `MQTT5 spec <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901124>`__ encoding values.
public enum PubackReasonCode {

    // Returned when the (QoS 1) publish was accepted by the recipient.
    // May be sent by the client or the server.
    case SUCCESS = 0

    // Returned when the (QoS 1) publish was accepted but there were no matching subscribers.
    // May only be sent by the server.
    case NO_MATCHING_SUBSCRIBERS = 16

    // Returned when the (QoS 1) publish was not accepted and the receiver does not want to specify a reason or none
    // of the other reason codes apply.
    // May be sent by the client or the server.
    case UNSPECIFIED_ERROR = 128

    // Returned when the (QoS 1) publish was valid but the receiver was not willing to accept it.
    // May be sent by the client or the server.
    case IMPLEMENTATION_SPECIFIC_ERROR = 131

    // Returned when the (QoS 1) publish was not authorized by the receiver.
    // May be sent by the client or the server.
    case NOT_AUTHORIZED = 135

    // Returned when the topic name was valid but the receiver was not willing to accept it.
    // May be sent by the client or the server.
    case TOPIC_NAME_INVALID = 144

    // Returned when the packet identifier used in the associated PUBLISH was already in use.
    // This can indicate a mismatch in the session state between client and server.
    // May be sent by the client or the server.
    case PACKET_IDENTIFIER_IN_USE = 145

    // Returned when the associated PUBLISH failed because an internal quota on the recipient was exceeded.
    // May be sent by the client or the server.
    case QUOTA_EXCEEDED = 151

    // Returned when the PUBLISH packet's payload format did not match its payload format indicator property.
    // May be sent by the client or the server.
    case case PAYLOAD_FORMAT_INVALID = 153
}

// Reason code inside SUBACK packet payloads.
// Enum values match `MQTT5 spec <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901178>`__ encoding values.
// This will only be sent by the server and not the client.
public enum SubackReasonCode {

    // Returned when the subscription was accepted and the maximum QoS sent will be QoS 0.
    case GRANTED_QOS_0 = 0

    // Returned when the subscription was accepted and the maximum QoS sent will be QoS 1.
    case GRANTED_QOS_1 = 1

    // Returned when the subscription was accepted and the maximum QoS sent will be QoS 2.
    case GRANTED_QOS_2 = 2

    // Returned when the connection was closed but the sender does not want to specify a reason or none
    // of the other reason codes apply.
    case UNSPECIFIED_ERROR = 128

    // Returned when the subscription was valid but the server did not accept it.
    case IMPLEMENTATION_SPECIFIC_ERROR = 131

    // Returned when the client was not authorized to make the subscription on the server.
    case NOT_AUTHORIZED = 135

    // Returned when the subscription topic filter was correctly formed but not allowed for the client.
    case TOPIC_FILTER_INVALID = 143

    // Returned when the packet identifier was already in use on the server.
    case PACKET_IDENTIFIER_IN_USE = 145

    // Returned when a subscribe-related quota set on the server was exceeded.
    case QUOTA_EXCEEDED = 151

    // Returned when the subscription's topic filter was a shared subscription and the server does not support
    // shared subscriptions.
    case SHARED_SUBSCRIPTIONS_NOT_SUPPORTED = 158

    // Returned when the SUBSCRIBE packet contained a subscription identifier and the server does not support
    // subscription identifiers.
    case SUBSCRIPTION_IDENTIFIERS_NOT_SUPPORTED = 161

    // Returned when the subscription's topic filter contains a wildcard but the server does not support
    // wildcard subscriptions.
    case WILDCARD_SUBSCRIPTIONS_NOT_SUPPORTED = 162
}

// Reason codes inside UNSUBACK packet payloads that specify the results for each topic filter in the associated
// UNSUBSCRIBE packet.
// Enum values match `MQTT5 spec <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901194>`__ encoding values.
public enum UnsubackReasonCode {

    // Returned when the unsubscribe was successful and the client is no longer subscribed to the topic filter on the server.
    case SUCCESS = 0

    // Returned when the topic filter did not match one of the client's existing topic filters on the server.
    case NO_SUBSCRIPTION_EXISTED = 17

    // Returned when the unsubscribe of the topic filter was not accepted and the server does not want to specify a
    // reason or none of the other reason codes apply.
    case UNSPECIFIED_ERROR = 128

    // Returned when the topic filter was valid but the server does not accept an unsubscribe for it.
    case IMPLEMENTATION_SPECIFIC_ERROR = 131

    // Returned when the client was not authorized to unsubscribe from that topic filter on the server.
    case NOT_AUTHORIZED = 135

    // Returned when the topic filter was correctly formed but is not allowed for the client on the server.
    case TOPIC_NAME_INVALID = 144

    // Returned when the packet identifier was already in use on the server.
    case PACKET_IDENTIFIER_IN_USE = 145
}

// Controls how the mqtt client should behave with respect to MQTT sessions.
public enum PacketType {

    // Default client session behavior. Maps to CLEAN.
    case DEFAULT = 0

    // Always ask for a clean session when connecting
    case CLEAN = 1

    // Always attempt to rejoin an existing session after an initial connection success.
    // Session rejoin requires an appropriate non-zero session expiry interval in the client's CONNECT options.
    case REJOIN_POST_SUCCESS = 2

    // Always attempt to rejoin an existing session.  Since the client does not support durable session persistence,
    // this option is not guaranteed to be spec compliant because any unacknowledged qos1 publishes (which are
    // part of the client session state) will not be present on the initial connection.  Until we support
    // durable session resumption, this option is technically spec-breaking, but useful.
    // Always rejoin requires an appropriate non-zero session expiry interval in the client's CONNECT options.
    case REJOIN_ALWAYS = 3
}

public enum ClientSessionBehaviorType {

}

public enum ExtendedValidationAndFlowControlOptions {

}

public enum ClienOperationQueueBehaviorType {

}

public enum ExponentialBackoffJitterMode {

}

public enum PayloadFormatIndicator {

}

public enum RetainHandlingType {

}

public enum OutboundTopicAliasBehaviorType {

}

public enum InboundTopicAliasBehaviorType {

}