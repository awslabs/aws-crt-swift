///  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
///  SPDX-License-Identifier: Apache-2.0.

/// MQTT message delivery quality of service.
/// Enum values match `MQTT5 spec <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901234>`__ encoding values.
public enum QoS: Int {

    /// The message is delivered according to the capabilities of the underlying network. No response is sent by the
    /// receiver and no retry is performed by the sender. The message arrives at the receiver either once or not at all.
    case atMostOnce = 0

    /// A level of service that ensures that the message arrives at the receiver at least once.
    case atLeastOnce = 1

    /// A level of service that ensures that the message arrives at the receiver exactly once.
    /// Note that this client does not currently support QoS 2 as of (March 2024)
    case exactlyOnce = 2
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
    case topicNameInvalid = 144

    /// Returned when the packet identifier was already in use on the server.
    case packetIdentifierInUse = 145
}

/// Controls how the mqtt client should behave with respect to MQTT sessions.
public enum ClientSessionBehaviorType: Int {

    /// Default client session behavior. Maps to CLEAN.
    case `default` = 0

    /// Always ask for a clean session when connecting
    case clean = 1

    /// Always attempt to rejoin an existing session after an initial connection success.
    /// Session rejoin requires an appropriate non-zero session expiry interval in the client's CONNECT options.
    case rejoinPostSuccess = 2

    /// Always attempt to rejoin an existing session.  Since the client does not support durable session persistence,
    /// this option is not guaranteed to be spec compliant because any unacknowledged qos1 publishes (which are
    /// part of the client session state) will not be present on the initial connection.  Until we support
    /// durable session resumption, this option is technically spec-breaking, but useful.
    /// Always rejoin requires an appropriate non-zero session expiry interval in the client's CONNECT options.
    case rejoinAlways = 3
}

/// Additional controls for client behavior with respect to operation validation and flow control; these checks
/// go beyond the MQTT5 spec to respect limits of specific MQTT brokers.
public enum ExtendedValidationAndFlowControlOptions: Int {

    /// Do not do any additional validation or flow control
    case none = 0

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
    case awsIotCoreDefaults = 1
}

/// Controls how disconnects affect the queued and in-progress operations tracked by the client.  Also controls
/// how operations are handled while the client is not connected.  In particular, if the client is not connected,
/// then any operation that would be failed on disconnect (according to these rules) will be rejected.
public enum ClientOperationQueueBehaviorType: Int {

    /// Default client operation queue behavior. Maps to FAIL_QOS0_PUBLISH_ON_DISCONNECT.
    case `default` = 0

    /// Re-queues QoS 1+ publishes on disconnect; un-acked publishes go to the front while unprocessed publishes stay
    /// in place.  All other operations (QoS 0 publishes, subscribe, unsubscribe) are failed.
    case failNonQos1PublishOnDisconnect = 1

    /// QoS 0 publishes that are not complete at the time of disconnection are failed.  Un-acked QoS 1+ publishes are
    /// re-queued at the head of the line for immediate retransmission on a session resumption.  All other operations
    /// are requeued in original order behind any retransmissions.
    case failQos0PublishOnDisconnect = 2

    /// All operations that are not complete at the time of disconnection are failed, except operations that
    /// the MQTT5 spec requires to be retransmitted (un-acked QoS1+ publishes).
    case failAllOnDisconnect = 3
}

/// Optional property describing a PUBLISH payload's format.
/// Enum values match `MQTT5 spec <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901111>`__ encoding values.
public enum PayloadFormatIndicator: Int {

    /// The payload is arbitrary binary data
    case awsMqtt5PfiBytes = 0

    /// The payload is a well-formed utf-8 string value.
    case awsMqtt5PfiUtf8 = 1
}

/// Configures how retained messages should be handled when subscribing with a topic filter that matches topics with
/// associated retained messages.
/// Enum values match `MQTT5 spec <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901169>`_ encoding values.
public enum RetainHandlingType: Int {

    /// The server should always send all retained messages on topics that match a subscription's filter.
    case sendOnSubscribe = 0

    /// The server should send retained messages on topics that match the subscription's filter, but only for the
    /// first matching subscription, per session.
    case sendOnSubscribeIfNew = 1

    /// Subscriptions must not trigger any retained message publishes from the server.
    case dontSend = 2
}

/// An enumeration that controls how the client applies topic aliasing to outbound publish packets.
/// Topic alias behavior is described in `MQTT5 Topic Aliasing <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901113>`_
public enum OutboundTopicAliasBehaviorType: Int {
    /// Maps to Disabled.  This keeps the client from being broken (by default) if the broker
    /// topic aliasing implementation has a problem.
    case `default` = 0

    ///  Outbound aliasing is the user's responsibility.  Client will cache and use
    ///  previously-established aliases if they fall within the negotiated limits of the connection.
    ///  The user must still always submit a full topic in their publishes because disconnections disrupt
    ///  topic alias mappings unpredictably.  The client will properly use a requested alias when the most-recently-seen
    ///  binding for a topic alias value matches the alias and topic in the publish packet.
    case manual = 1

    /// (Recommended) The client will ignore any user-specified topic aliasing and instead use an LRU cache to drive
    ///  alias usage.
    case lru = 2

    /// Completely disable outbound topic aliasing.
    case disabled = 3
}

/// An enumeration that controls whether or not the client allows the broker to send publishes that use topic
/// aliasing.
/// Topic alias behavior is described in `MQTT5 Topic Aliasing <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901113>`_
public enum InboundTopicAliasBehaviorType: Int {

    /// Maps to Disabled.  This keeps the client from being broken (by default) if the broker
    /// topic aliasing implementation has a problem.
    case `default` = 0

    /// Allow the server to send PUBLISH packets to the client that use topic aliasing
    case enabled = 1

    /// Forbid the server from sending PUBLISH packets to the client that use topic aliasing
    case disabled = 2
}

/// Configuration for all client topic aliasing behavior.
public class TopicAliasingOptions {

    /// Controls what kind of outbound topic aliasing behavior the client should attempt to use.  If topic aliasing is not supported by the server, this setting has no effect and any attempts to directly manipulate the topic alias id in outbound publishes will be ignored.  If left undefined, then outbound topic aliasing is disabled.
    var outboundBehavior: OutboundTopicAliasBehaviorType?

    /// If outbound topic aliasing is set to LRU, this controls the maximum size of the cache.  If outbound topic aliasing is set to LRU and this is zero or undefined, a sensible default is used (25).  If outbound topic aliasing is not set to LRU, then this setting has no effect.
    var outboundCacheMaxSize: UInt16?

    /// Controls whether or not the client allows the broker to use topic aliasing when sending publishes.  Even if inbound topic aliasing is enabled, it is up to the server to choose whether or not to use it.  If left undefined, then inbound topic aliasing is disabled.
    var inboundBehavior: InboundTopicAliasBehaviorType?

    /// If inbound topic aliasing is enabled, this will control the size of the inbound alias cache.  If inbound aliases are enabled and this is zero or undefined, then a sensible default will be used (25).  If inbound aliases are disabled, this setting has no effect.  Behaviorally, this value overrides anything present in the topic_alias_maximum field of the CONNECT packet options.
    var inboundCacheMaxSize: UInt16?

}

/// Mqtt behavior settings that are dynamically negotiated as part of the CONNECT/CONNACK exchange.
/// While you can infer all of these values from a combination of:
/// - defaults as specified in the mqtt5 spec
/// - your CONNECT settings
/// - the CONNACK from the broker
/// the client instead does the combining for you and emits a NegotiatedSettings object with final, authoritative values.
/// Negotiated settings are communicated with every successful connection establishment.
public class NegotiatedSettings {

    /// The maximum QoS allowed for publishes on this connection instance
    var maximumQos: QoS

    /// The amount of time in seconds the server will retain the MQTT session after a disconnect.
    var sessionExpiryIntervalSec: UInt32

    /// The number of in-flight QoS 1 and QoS 2 publications the server is willing to process concurrently.
    var receiveMaximumFromServer: UInt16

    /// The maximum packet size the server is willing to accept.
    var maximumPacketSizeToServer: UInt32

    /// The maximum allowed topic alias value on publishes sent from client to server
    var topicAliasMaximumToServer: UInt16

    /// The maximum allowed topic alias value on publishes sent from server to client
    var topicAliasMaximumToClient: UInt16

    /// The maximum amount of time in seconds between client packets. The client will use PINGREQs to ensure this limit is not breached.  The server will disconnect the client for inactivity if no MQTT packet is received in a time interval equal to 1.5 x this value.
    var serverKeepAliveSec: UInt16

    /// Whether the server supports retained messages.
    var retainAvailable: Bool

    /// Whether the server supports wildcard subscriptions.
    var wildcardSubscriptionsAvailable: Bool

    /// Whether the server supports subscription identifiers
    var subscriptionIdentifiersAvailable: Bool

    /// Whether the server supports shared subscriptions
    var sharedSubscriptionsAvailable: Bool

    /// Whether the client has rejoined an existing session.
    var rejoinedSession: Bool

    /// The final client id in use by the newly-established connection.  This will be the configured client id if one was given in the configuration, otherwise, if no client id was specified, this will be the client id assigned by the server.  Reconnection attempts will always use the auto-assigned client id, allowing for auto-assigned session resumption.
    var clientId: String

    init(maximumQos: QoS, sessionExpiryIntervalSec: UInt32, receiveMaximumFromServer: UInt16, maximumPacketSizeToServer: Uint32,
        topicAliasMaximumToServer: UInt16, topicAliasMaximumToClient: UInt16, serverKeepAliveSec: UInt16, retainAvailable: Bool,
        wildcardSubscriptionsAvailable: Bool, subscriptionIdentifiersAvailable: Bool, sharedSubscriptionsAvailable: Bool, rejoinedSession: Bool,
        clientId: String) {
            this.maximumQos = maximumQos
            this.sessionExpiryIntervalSec = sessionExpiryIntervalSec
            this.receiveMaximumFromServer = receiveMaximumFromServer
            this.maximumPacketSizeToServer = maximumPacketSizeToServer
            this.topicAliasMaximumToServer = topicAliasMaximumToServer
            this.topicAliasMaximumToClient = topicAliasMaximumToClient
            this.serverKeepAliveSec = serverKeepAliveSec
            this.retainAvailable = retainAvailable
            this.wildcardSubscriptionsAvailable = wildcardSubscriptionsAvailable
            this.subscriptionIdentifiersAvailable = subscriptionIdentifiersAvailable
            this.sharedSubscriptionsAvailable = sharedSubscriptionsAvailable
            this.rejoinedSession = rejoinedSession
            this.clientId = clientId
        }
}

/// Mqtt5 User Property
public class UserProperty {

    /// Property name
    var name: String

    /// Property value
    var value: String

    init(name: String, value: String){
        this.name = name
        this.value = value
    }
}

/// Data model of an `MQTT5 PUBLISH <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901100>`_ packet
public class PublishPacket {

    /// The payload of the publish message.
    var payload: String // Unicode objects are converted to C Strings using 'utf-8' encoding

    /// The MQTT quality of service associated with this PUBLISH packet.
    var qos: QoS = QoS.atMostOnce

    /// True if this is a retained message, false otherwise.
    var retain: Bool = false

    /// The topic associated with this PUBLISH packet.
    var topic: String

    /// Property specifying the format of the payload data. The mqtt5 client does not enforce or use this value in a meaningful way.
    var payloadFormatIndicator: PayloadFormatIndicator

    /// Sent publishes - indicates the maximum amount of time allowed to elapse for message delivery before the server should instead delete the message (relative to a recipient). Received publishes - indicates the remaining amount of time (from the server's perspective) before the message would have been deleted relative to the subscribing client. If left None, indicates no expiration timeout.
    var messageExpiryIntervalSec: Int

    /// An integer value that is used to identify the Topic instead of using the Topic Name.  On outbound publishes, this will only be used if the outbound topic aliasing behavior has been set to Manual.
    var topicAlias: Int

    /// Opaque topic string intended to assist with request/response implementations.  Not internally meaningful to MQTT5 or this client.
    var responseTopic: String

    /// Opaque binary data used to correlate between publish messages, as a potential method for request-response implementation.  Not internally meaningful to MQTT5.
    var correlationData: String // Unicode objects are converted to C Strings using 'utf-8' encoding

    /// The subscription identifiers of all the subscriptions this message matched.
    var subscriptionIdentifiers: [Int] // ignore attempts to set but provide in received packets

    /// Property specifying the content type of the payload.  Not internally meaningful to MQTT5.
    var contentType: String

    /// Array of MQTT5 user properties included with the packet.
    var userProperties: [UserProperty]

    init(qos: QoS, topic: String){
        this.qos = qos
        this.topic = topic
    }
}

/// "Data model of an `MQTT5 PUBACK <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901121>`_ packet
public class PubackPacket {

    /// Success indicator or failure reason for the associated PUBLISH packet.
    var reasonCode: PubackReasonCode

    /// Additional diagnostic information about the result of the PUBLISH attempt.
    var reasonString: String

    /// Array of MQTT5 user properties included with the packet.
    var userProperties: [UserProperty]
}

/// Configures a single subscription within a Subscribe operation
public class Subscription {

    /// The topic filter to subscribe to
    var topicFilter: String

    /// The maximum QoS on which the subscriber will accept publish messages
    var qos: QoS = QoS.atMostOnce

    /// Whether the server will not send publishes to a client when that client was the one who sent the publish
    var noLocal: Bool = false

    /// Whether messages sent due to this subscription keep the retain flag preserved on the message
    var retainAsPublished: Bool = false

    /// Whether retained messages on matching topics be sent in reaction to this subscription
    var retainHandlingType = RetainHandlingType.sendOnSubscribe
}

/// Data model of an `MQTT5 SUBSCRIBE <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901161>`_ packet.
public class SubscribePacket {

    /// Array of topic filters that the client wishes to listen to
    var subscriptions: [Subscription]

    /// The positive int to associate with all topic filters in this request.  Publish packets that match a subscription in this request should include this identifier in the resulting message.
    var subscriptionIdentifier: Int

    /// Array of MQTT5 user properties included with the packet.
    var userProperties: [UserProperty]
}

/// Data model of an `MQTT5 SUBACK <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901171>`_ packet.
public class SubackPacket {

    /// Additional diagnostic information about the result of the SUBSCRIBE attempt.
    var reasonString: String

    /// Array of MQTT5 user properties included with the packet.
    var userProperties: [UserProperty]

    /// Array of reason codes indicating the result of each individual subscription entry in the associated SUBSCRIBE packet.
    var reasonCodes: [SubackReasonCode]
}

/// Data model of an `MQTT5 UNSUBSCRIBE <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc384800445>`_ packet.
public class UnsubscribePacket {

    /// Array of topic filters that the client wishes to unsubscribe from.
    var topicFilters: [String]

    /// Array of MQTT5 user properties included with the packet.
    var userProperties: [UserProperty]
}

/// Data model of an `MQTT5 UNSUBACK <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc471483687>`_ packet.
public class UnsubackPacket {

    /// Additional diagnostic information about the result of the UNSUBSCRIBE attempt.
    var reasonString: String

    /// Array of MQTT5 user properties included with the packet.
    var userProperties: [UserProperty]

    /// Array of reason codes indicating the result of unsubscribing from each individual topic filter entry in the associated UNSUBSCRIBE packet.
    var reasonCodes: [DisconnectReasonCode]
}

/// Data model of an `MQTT5 DISCONNECT <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901205>`_ packet.
public class DisconnectPacket {

    /// Value indicating the reason that the sender is closing the connection
    var reasonCode: DisconnectReasonCode = DisconnectReasonCode.normalDisconnection

    /// A change to the session expiry interval negotiated at connection time as part of the disconnect.  Only valid for DISCONNECT packets sent from client to server.  It is not valid to attempt to change session expiry from zero to a non-zero value.
    var sessionExpiryIntervalSec: Int

    /// Additional diagnostic information about the reason that the sender is closing the connection
    var reasonString: String

    /// Array of MQTT5 user properties included with the packet.
    var userProperties: [UserProperty]

    /// Property indicating an alternate server that the client may temporarily or permanently attempt to connect to instead of the configured endpoint.  Will only be set if the reason code indicates another server may be used (ServerMoved, UseAnotherServer).
    var serverReference: String
}

/// Defines signature of the Publish callback
typealias OnPublishCallback = () -> Void

/// Defines signature of the Lifecycle Event Stopped callback
typealias OnLifecycleEventStopped = () -> Void

/// Data model of an `MQTT5 CONNECT <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901033>`_ packet.
public class ConnectOptions {

    /// The maximum time interval, in seconds, that is permitted to elapse between the point at which the client finishes transmitting one MQTT packet and the point it starts sending the next.  The client will use PINGREQ packets to maintain this property. If the responding CONNACK contains a keep alive property value, then that is the negotiated keep alive value. Otherwise, the keep alive sent by the client is the negotiated value.
    var keepAliveIntervalSec: UInt16

    /// A unique string identifying the client to the server.  Used to restore session state between connections. If left empty, the broker will auto-assign a unique client id.  When reconnecting, the mqtt5 client will always use the auto-assigned client id.
    var clientId: String

    /// A string value that the server may use for client authentication and authorization.
    var username: String

    /// Opaque binary data that the server may use for client authentication and authorization.
    var password: String

    /// A time interval, in seconds, that the client requests the server to persist this connection's MQTT session state for.  Has no meaning if the client has not been configured to rejoin sessions.  Must be non-zero in order to successfully rejoin a session. If the responding CONNACK contains a session expiry property value, then that is the negotiated session expiry value.  Otherwise, the session expiry sent by the client is the negotiated value.
    var sessionExpiryIntervalSec: UInt32

    /// If true, requests that the server send response information in the subsequent CONNACK.  This response information may be used to set up request-response implementations over MQTT, but doing so is outside the scope of the MQTT5 spec and client.
    var requestResponseInformation: Bool

    /// If true, requests that the server send additional diagnostic information (via response string or user properties) in DISCONNECT or CONNACK packets from the server.
    var requestProblemInformation: Bool

    /// Notifies the server of the maximum number of in-flight QoS 1 and 2 messages the client is willing to handle.  If omitted or None, then no limit is requested.
    var receiveMaximum: UInt16

    /// Notifies the server of the maximum packet size the client is willing to handle.  If omitted or None, then no limit beyond the natural limits of MQTT packet size is requested.
    var maximumPacketSize: UInt32

    /// A time interval, in seconds, that the server should wait (for a session reconnection) before sending the will message associated with the connection's session.  If omitted or None, the server will send the will when the associated session is destroyed.  If the session is destroyed before a will delay interval has elapsed, then the will must be sent at the time of session declassion.
    var willDelayIntervalSec: UInt32

    /// The definition of a message to be published when the connection's session is destroyed by the server or when the will delay interval has elapsed, whichever comes first.  If None, then nothing will be sent.
    var will: PublishPacket

    /// Array of MQTT5 user properties included with the packet.
    var userProperties: [UserProperty]
}

/// Data model of an `MQTT5 CONNACK <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901074>`_ packet.
public class ConnackPacket {

    /// True if the client rejoined an existing session on the server, false otherwise.
    var sessionPresent: Bool

    /// Indicates either success or the reason for failure for the connection attempt.
    var reasonCode: ConnectReasonCode

    /// A time interval, in seconds, that the server will persist this connection's MQTT session state for.  If present, this value overrides any session expiry specified in the preceding CONNECT packet.
    var sessionExpiryIntervalSec: Int

    /// The maximum amount of in-flight QoS 1 or 2 messages that the server is willing to handle at once. If omitted or None, the limit is based on the valid MQTT packet id space (65535).
    var receiveMaximum: Int

    /// The maximum message delivery quality of service that the server will allow on this connection.
    var maximumQos: QoS

    /// Indicates whether the server supports retained messages.  If None, retained messages are supported.
    var retainAvailable: Bool

    /// Specifies the maximum packet size, in bytes, that the server is willing to accept.  If None, there is no limit beyond what is imposed by the MQTT spec itself.
    var maximumPacketSize: Int

    /// Specifies a client identifier assigned to this connection by the server.  Only valid when the client id of the preceding CONNECT packet was left empty.
    var assignedClientIdentifier: String

    /// The maximum allowed value for topic aliases in outbound publish packets.  If 0 or None, then outbound topic aliasing is not allowed.
    var topicAliasMaximum: Int

    /// Additional diagnostic information about the result of the connection attempt.
    var reasonString: String

    /// Array of MQTT5 user properties included with the packet.
    var userProperties: [UserProperty]

    /// Indicates whether the server supports wildcard subscriptions.  If None, wildcard subscriptions are supported.
    var wildcardSubscriptionsAvailable: Bool

    /// Indicates whether the server supports subscription identifiers.  If None, subscription identifiers are supported.
    var subscriptionIdentifiersAvailable: Bool

    /// Indicates whether the server supports shared subscription topic filters.  If None, shared subscriptions are supported.
    var sharedSubscriptionAvailable: Bool

    /// Server-requested override of the keep alive interval, in seconds.  If None, the keep alive value sent by the client should be used.
    var serverKeepAliveSec: Int

    /// A value that can be used in the creation of a response topic associated with this connection. MQTT5-based request/response is outside the purview of the MQTT5 spec and this client.
    var responseInformation: String

    /// Property indicating an alternate server that the client may temporarily or permanently attempt to connect to instead of the configured endpoint.  Will only be set if the reason code indicates another server may be used (ServerMoved, UseAnotherServer).
    var serverReference: String
}

/// Configuration for the creation of MQTT5 clients
public class ClientOptions {
    /// Host name of the MQTT server to connect to.
    var hostName: String

    /// Network port of the MQTT server to connect to.
    var port: UInt32

    /// The Client bootstrap used
    var bootstrap: ClientBootstrap

    /// The socket properties of the underlying MQTT connections made by the client or None if defaults are used.
    var socketOptions: SocketOptions

    /// The TLS context for secure socket connections. If None, then a plaintext connection will be used.
    var tlsCtx: TLSContext

    /// The (tunneling) HTTP proxy usage when establishing MQTT connections
    var httpProxyOptions: HTTPProxyOptions

    // TODO WebSocket implementation
    /// This callback allows a custom transformation of the HTTP request that acts as the websocket handshake. Websockets will be used if this is set to a valid transformation callback.  To use websockets but not perform a transformation, just set this as a trivial completion callback.  If None, the connection will be made with direct MQTT.
    // var websocketHandshakeTransform: Callable[[WebsocketHandshakeTransformArgs], None] = None

    /// All configurable options with respect to the CONNECT packet sent by the client, including the will. These connect properties will be used for every connection attempt made by the client.
    var connectOptions: ConnectOptions

    /// How the MQTT5 client should behave with respect to MQTT sessions.
    var sessionBehavior: ClientSessionBehaviorType

    /// The additional controls for client behavior with respect to operation validation and flow control; these checks go beyond the base MQTT5 spec to respect limits of specific MQTT brokers.
    var extendedValidationAndFlowControlOptions: ExtendedValidationAndFlowControlOptions

    /// Returns how disconnects affect the queued and in-progress operations tracked by the client.  Also controls how new operations are handled while the client is not connected.  In particular, if the client is not connected, then any operation that would be failed on disconnect (according to these rules) will also be rejected.
    var offlineQueueBehavior: ClientOperationQueueBehaviorType

    /// How the reconnect delay is modified in order to smooth out the distribution of reconnection attempt timepoints for a large set of reconnecting clients.
    var retryJitterMode: ExponentialBackoffJitterMode

    /// The minimum amount of time to wait to reconnect after a disconnect. Exponential backoff is performed with jitter after each connection failure.
    var minReconnectDelayMs: UInt64

    /// The maximum amount of time to wait to reconnect after a disconnect.  Exponential backoff is performed with jitter after each connection failure.
    var maxReconnectDelayMs: UInt64

    /// The amount of time that must elapse with an established connection before the reconnect delay is reset to the minimum. This helps alleviate bandwidth-waste in fast reconnect cycles due to permission failures on operations.
    var minConnectedTimeToResetReconnectDelayMs: UInt64

    /// The time interval to wait after sending a PINGREQ for a PINGRESP to arrive. If one does not arrive, the client will close the current connection.
    var pingTimeoutMs: UInt32

    /// The time interval to wait after sending a CONNECT request for a CONNACK to arrive.  If one does not arrive, the connection will be shut down.
    var connackTimeoutMs: UInt32

    /// The time interval to wait for an ack after sending a QoS 1+ PUBLISH, SUBSCRIBE, or UNSUBSCRIBE before failing the operation.
    var ackTimeoutSec: UInt32

    /// All configurable options with respect to client topic aliasing behavior.
    var topicAliasingOptions: TopicAliasingOptions

    /// Callback for all publish packets received by client.
    var onPublishCallbackFn: OnPublishCallback? // onPublish_callback_fn: Callable[[PublishReceivedData], None]

    /// Callback for Lifecycle Event Stopped.
    var onLifecycleEventStoppedFn: OnLifecycleEventStopped? // onLifecycleEventStoppedFn: Callable[[LifecycleStoppedData], None]

    /// Callback for Lifecycle Event Attempting Connect.
    // onLifecycleEventAttemptingConnectFn: Callable[[LifecycleAttemptingConnectData], None]

    /// Callback for Lifecycle Event Connection Success.
    // onLifecycleEventConnectionSuccessFn: Callable[[LifecycleConnectSuccessData], None]

    /// Callback for Lifecycle Event Connection Failure.
    // onLifecycleEventConnectionFailureFn: Callable[[LifecycleConnectFailureData], None]

    /// Callback for Lifecycle Event Disconnection.
    // onLifecycleEventDisconnectionFn: Callable[[LifecycleDisconnectData], None]
}

/// Dataclass containing some simple statistics about the current state of the client's queue of operations
public class ClientOperationStatistics {

    /// Total number of operations submitted to the client that have not yet been completed.  Unacked operations are a subset of this.
    var incompleteOperationCount: Int = 0

    /// Total packet size of operations submitted to the client that have not yet been completed.  Unacked operations are a subset of this.
    var incompleteOperationSize: Int = 0

    /// Total number of operations that have been sent to the server and are waiting for a corresponding ACK before they can be completed.
    var unackedOperationCount: Int = 0

    /// Total packet size of operations that have been sent to the server and are waiting for a corresponding ACK before they can be completed.
    var unackedOperationSize: Int = 0
}
