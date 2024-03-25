///  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
///  SPDX-License-Identifier: Apache-2.0.

import AwsCMqtt


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
    case topicFilterInvalid = 143

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
    case bytes = 0

    /// The payload is a well-formed utf-8 string value.
    case utf8 = 1
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
public class TopicAliasingOptions: CStruct {

    /// Controls what kind of outbound topic aliasing behavior the client should attempt to use.  If topic aliasing is not supported by the server, this setting has no effect and any attempts to directly manipulate the topic alias id in outbound publishes will be ignored.  If left undefined, then outbound topic aliasing is disabled.
    public var outboundBehavior: OutboundTopicAliasBehaviorType?

    /// If outbound topic aliasing is set to LRU, this controls the maximum size of the cache.  If outbound topic aliasing is set to LRU and this is zero or undefined, a sensible default is used (25).  If outbound topic aliasing is not set to LRU, then this setting has no effect.
    public var outboundCacheMaxSize: UInt16?

    /// Controls whether or not the client allows the broker to use topic aliasing when sending publishes.  Even if inbound topic aliasing is enabled, it is up to the server to choose whether or not to use it.  If left undefined, then inbound topic aliasing is disabled.
    public var inboundBehavior: InboundTopicAliasBehaviorType?

    /// If inbound topic aliasing is enabled, this will control the size of the inbound alias cache.  If inbound aliases are enabled and this is zero or undefined, then a sensible default will be used (25).  If inbound aliases are disabled, this setting has no effect.  Behaviorally, this value overrides anything present in the topic_alias_maximum field of the CONNECT packet options.
    public var inboundCacheMaxSize: UInt16?

    typealias RawType = aws_mqtt5_client_topic_alias_options
    func withCStruct<Result>(_ body: (aws_mqtt5_client_topic_alias_options) -> Result) -> Result {
        var raw_topic_alias_options = aws_mqtt5_client_topic_alias_options()
        if let _outboundBehavior = outboundBehavior {
            raw_topic_alias_options.outbound_topic_alias_behavior =
                aws_mqtt5_client_outbound_topic_alias_behavior_type(UInt32(_outboundBehavior.rawValue))
        }

        if let _outboundCacheMaxSize = outboundCacheMaxSize {
            raw_topic_alias_options.outbound_alias_cache_max_size = _outboundCacheMaxSize
        }

        if let _inboundBehavior = inboundBehavior {
            raw_topic_alias_options.inbound_topic_alias_behavior =
                aws_mqtt5_client_inbound_topic_alias_behavior_type(UInt32(_inboundBehavior.rawValue))
        }

        if let _inboundCacheMaxSize = inboundCacheMaxSize {
            raw_topic_alias_options.inbound_alias_cache_size = _inboundCacheMaxSize
        }

        return body(raw_topic_alias_options)
    }

}

/// Dataclass containing some simple statistics about the current state of the client's queue of operations
public class ClientOperationStatistics {

    /// Total number of operations submitted to the client that have not yet been completed.  Unacked operations are a subset of this.
    public let incompleteOperationCount: UInt64

    /// Total packet size of operations submitted to the client that have not yet been completed.  Unacked operations are a subset of this.
    public let incompleteOperationSize: UInt64

    /// Total number of operations that have been sent to the server and are waiting for a corresponding ACK before they can be completed.
    public let unackedOperationCount: UInt64

    /// Total packet size of operations that have been sent to the server and are waiting for a corresponding ACK before they can be completed.
    public let unackedOperationSize: UInt64

    public init (incompleteOperationCount: UInt64, incompleteOperationSize: UInt64,
        unackedOperationCount: UInt64, unackedOperationSize: UInt64) {
            self.incompleteOperationCount = incompleteOperationCount
            self.incompleteOperationSize = incompleteOperationSize
            self.unackedOperationCount = unackedOperationCount
            self.unackedOperationSize = unackedOperationSize
        }
}

/// Class containing data related to a Publish Received Callback
public class PublishReceivedData {

    /// Data model of an `MQTT5 PUBLISH <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901100>`_ packet.
    public let publishPacket: PublishPacket

    public init (publishPacket: PublishPacket) {
        self.publishPacket = publishPacket
    }
}

/// Defines signature of the Publish callback
public typealias OnPublishReceived = (PublishReceivedData) -> Void

/// Class containing results of an Stopped Lifecycle Event. Currently unused.
public class LifecycleStoppedData { }

/// Defines signature of the Lifecycle Event Stopped callback
public typealias OnLifecycleEventStopped = (LifecycleStoppedData) -> Void

/// Class containing results of an Attempting Connect Lifecycle Event. Currently unused.
public class LifecycleAttemptingConnectData { }

/// Defines signature of the Lifecycle Event Attempting Connect callback
public typealias OnLifecycleEventAttemptingConnect = (LifecycleAttemptingConnectData) -> Void

/// Class containing results of a Connect Success Lifecycle Event.
public class LifecycleConnectSuccessData {

    /// Data model of an `MQTT5 CONNACK <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901074>`_ packet.
    public let connackPacket: ConnackPacket

    /// Mqtt behavior settings that have been dynamically negotiated as part of the CONNECT/CONNACK exchange.
    public let negotiatedSettings: NegotiatedSettings

    public init (connackPacket: ConnackPacket, negotiatedSettings: NegotiatedSettings) {
        self.connackPacket = connackPacket
        self.negotiatedSettings = negotiatedSettings
    }
}

/// Defines signature of the Lifecycle Event Connection Success callback
public typealias OnLifecycleEventConnectionSuccess = (LifecycleConnectSuccessData) -> Void

/// Dataclass containing results of a Connect Failure Lifecycle Event.
public class LifecycleConnectFailureData {

    /// Error which caused connection failure.
    public let crtError: CRTError

    /// Data model of an `MQTT5 CONNACK <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901074>`_ packet.
    public let connackPacket: ConnackPacket

    public init (crtError: CRTError, connackPacket: ConnackPacket) {
        self.crtError = crtError
        self.connackPacket = connackPacket
    }

}

/// Defines signature of the Lifecycle Event Connection Failure callback
public typealias OnLifecycleEventConnectionFailure = (LifecycleConnectFailureData) -> Void

/// Dataclass containing results of a Disconnect Lifecycle Event
public class LifecycleDisconnectData {

    /// Error which caused disconnection.
    public let crtError: CRTError

    /// Data model of an `MQTT5 DISCONNECT <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901205>`_ packet.
    public let disconnectPacket: DisconnectPacket

    public init (crtError: CRTError, disconnectPacket: DisconnectPacket) {
        self.crtError = crtError
        self.disconnectPacket = disconnectPacket
    }
}

/// Defines signature of the Lifecycle Event Disconnection callback
public typealias OnLifecycleEventDisconnection = (LifecycleDisconnectData) -> Void

/// Mqtt behavior settings that are dynamically negotiated as part of the CONNECT/CONNACK exchange.
/// While you can infer all of these values from a combination of:
/// - defaults as specified in the mqtt5 spec
/// - your CONNECT settings
/// - the CONNACK from the broker
/// the client instead does the combining for you and emits a NegotiatedSettings object with final, authoritative values.
/// Negotiated settings are communicated with every successful connection establishment.
public class NegotiatedSettings {

    /// The maximum QoS allowed for publishes on this connection instance
    public let maximumQos: QoS

    /// The amount of time in seconds the server will retain the MQTT session after a disconnect.
    public let sessionExpiryIntervalSec: UInt32

    /// The number of in-flight QoS 1 and QoS 2 publications the server is willing to process concurrently.
    public let receiveMaximumFromServer: UInt16

    /// The maximum packet size the server is willing to accept.
    public let maximumPacketSizeToServer: UInt32

    /// The maximum allowed topic alias value on publishes sent from client to server
    public let topicAliasMaximumToServer: UInt16

    /// The maximum allowed topic alias value on publishes sent from server to client
    public let topicAliasMaximumToClient: UInt16

    /// The maximum amount of time in seconds between client packets. The client will use PINGREQs to ensure this limit is not breached.  The server will disconnect the client for inactivity if no MQTT packet is received in a time interval equal to 1.5 x this value.
    public let serverKeepAliveSec: UInt16

    /// Whether the server supports retained messages.
    public let retainAvailable: Bool

    /// Whether the server supports wildcard subscriptions.
    public let wildcardSubscriptionsAvailable: Bool

    /// Whether the server supports subscription identifiers
    public let subscriptionIdentifiersAvailable: Bool

    /// Whether the server supports shared subscriptions
    public let sharedSubscriptionsAvailable: Bool

    /// Whether the client has rejoined an existing session.
    public let rejoinedSession: Bool

    /// The final client id in use by the newly-established connection.  This will be the configured client id if one was given in the configuration, otherwise, if no client id was specified, this will be the client id assigned by the server.  Reconnection attempts will always use the auto-assigned client id, allowing for auto-assigned session resumption.
    public let clientId: String

    public init (
        maximumQos: QoS,
        sessionExpiryIntervalSec: UInt32,
        receiveMaximumFromServer: UInt16,
        maximumPacketSizeToServer: UInt32,
        topicAliasMaximumToServer: UInt16,
        topicAliasMaximumToClient: UInt16,
        serverKeepAliveSec: UInt16,
        retainAvailable: Bool,
        wildcardSubscriptionsAvailable: Bool,
        subscriptionIdentifiersAvailable: Bool,
        sharedSubscriptionsAvailable: Bool,
        rejoinedSession: Bool,
        clientId: String) {

        self.maximumQos = maximumQos
        self.sessionExpiryIntervalSec = sessionExpiryIntervalSec
        self.receiveMaximumFromServer = receiveMaximumFromServer
        self.maximumPacketSizeToServer = maximumPacketSizeToServer
        self.topicAliasMaximumToServer = topicAliasMaximumToServer
        self.topicAliasMaximumToClient = topicAliasMaximumToClient
        self.serverKeepAliveSec = serverKeepAliveSec
        self.retainAvailable = retainAvailable
        self.wildcardSubscriptionsAvailable = wildcardSubscriptionsAvailable
        self.subscriptionIdentifiersAvailable = subscriptionIdentifiersAvailable
        self.sharedSubscriptionsAvailable = sharedSubscriptionsAvailable
        self.rejoinedSession = rejoinedSession
        self.clientId = clientId
    }
}

/// Data model of an `MQTT5 CONNECT <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901033>`_ packet.
public class MqttConnectOptions: CStruct {
    /// The maximum time interval, in seconds, that is permitted to elapse between the point at which the client finishes transmitting one MQTT packet and the point it starts sending the next.  The client will use PINGREQ packets to maintain this property. If the responding CONNACK contains a keep alive property value, then that is the negotiated keep alive value. Otherwise, the keep alive sent by the client is the negotiated value.
    public let keepAliveIntervalSec: UInt16?

    /// A unique string identifying the client to the server.  Used to restore session state between connections. If left empty, the broker will auto-assign a unique client id.  When reconnecting, the mqtt5 client will always use the auto-assigned client id.
    public let clientId: String?

    /// A string value that the server may use for client authentication and authorization.
    public let username: String?

    /// Opaque binary data that the server may use for client authentication and authorization.
    public let password: String?

    /// A time interval, in seconds, that the client requests the server to persist this connection's MQTT session state for.  Has no meaning if the client has not been configured to rejoin sessions.  Must be non-zero in order to successfully rejoin a session. If the responding CONNACK contains a session expiry property value, then that is the negotiated session expiry value.  Otherwise, the session expiry sent by the client is the negotiated value.
    public let sessionExpiryIntervalSec: UInt32?

    /// If true, requests that the server send response information in the subsequent CONNACK.  This response information may be used to set up request-response implementations over MQTT, but doing so is outside the scope of the MQTT5 spec and client.
    public let requestResponseInformation: Bool?

    /// If true, requests that the server send additional diagnostic information (via response string or user properties) in DISCONNECT or CONNACK packets from the server.
    public let requestProblemInformation: Bool?

    /// Notifies the server of the maximum number of in-flight QoS 1 and 2 messages the client is willing to handle.  If omitted or None, then no limit is requested.
    public let receiveMaximum: UInt16?

    /// Notifies the server of the maximum packet size the client is willing to handle.  If omitted or None, then no limit beyond the natural limits of MQTT packet size is requested.
    public let maximumPacketSize: UInt32?

    /// A time interval, in seconds, that the server should wait (for a session reconnection) before sending the will message associated with the connection's session.  If omitted or None, the server will send the will when the associated session is destroyed.  If the session is destroyed before a will delay interval has elapsed, then the will must be sent at the time of session declassion.
    public let willDelayIntervalSec: UInt32?

    /// The definition of a message to be published when the connection's session is destroyed by the server or when the will delay interval has elapsed, whichever comes first.  If None, then nothing will be sent.
    public let will: PublishPacket?

    /// Array of MQTT5 user properties included with the packet.
    public let userProperties: [UserProperty]?

    public init (
        keepAliveIntervalSec: UInt16? = nil,
        clientId: String? = nil,
        username: String? = nil,
        password: String? = nil,
        sessionExpiryIntervalSec: UInt32? = nil,
        requestResponseInformation: Bool? = nil,
        requestProblemInformation: Bool? = nil,
        receiveMaximum: UInt16? = nil,
        maximumPacketSize: UInt32? = nil,
        willDelayIntervalSec: UInt32? = nil,
        will: PublishPacket? = nil,
        userProperties: [UserProperty]? = nil) {

        self.keepAliveIntervalSec = keepAliveIntervalSec
        self.clientId = clientId
        self.username = username
        self.password = password
        self.sessionExpiryIntervalSec = sessionExpiryIntervalSec
        self.requestResponseInformation = requestResponseInformation
        self.requestProblemInformation = requestProblemInformation
        self.receiveMaximum = receiveMaximum
        self.maximumPacketSize = maximumPacketSize
        self.willDelayIntervalSec = willDelayIntervalSec
        self.will = will
        self.userProperties = userProperties
    }

    typealias RawType = aws_mqtt5_packet_connect_view
    func withCStruct<Result>( _ body: (RawType) -> Result) -> Result {

        var raw_connect_options = aws_mqtt5_packet_connect_view()
        if let _keepAlive = self.keepAliveIntervalSec {
            raw_connect_options.keep_alive_interval_seconds = _keepAlive
        }

        if let _sessionExpiryIntervalSec = self.sessionExpiryIntervalSec {
            // convert UInt32 to UnsafePointer<UInt32>
            raw_connect_options.session_expiry_interval_seconds = withUnsafePointer(
                to: _sessionExpiryIntervalSec) { _sessionExpiryIntervalSecPointer in
                return _sessionExpiryIntervalSecPointer
            }
        }

        if let _requestResponseInformation = self.requestResponseInformation?.uint8Value {
            raw_connect_options.request_response_information = withUnsafePointer(to: _requestResponseInformation) { _requestResponseInformationPointer in
                return _requestResponseInformationPointer
            }
        }

        if let _requestProblemInformation = self.requestProblemInformation?.uint8Value {
            raw_connect_options.request_problem_information = withUnsafePointer(to: _requestProblemInformation) { _requestProblemInformationPointer in
                return _requestProblemInformationPointer
            }
        }

        if let _receiveMaximum = self.receiveMaximum {
            raw_connect_options.receive_maximum = withUnsafePointer(to: _receiveMaximum) { _receiveMaximumPointer in
                return _receiveMaximumPointer
            }
        }

        if let _maximumPacketSize = self.maximumPacketSize {
            raw_connect_options.maximum_packet_size_bytes = withUnsafePointer(to: _maximumPacketSize) { _maximumPacketSizePointer in
                return _maximumPacketSizePointer
            }
        }

        if let _willDelayIntervalSec = self.willDelayIntervalSec {
            raw_connect_options.will_delay_interval_seconds = withUnsafePointer(to: _willDelayIntervalSec) { _willDelayIntervalSecPointer in
                return _willDelayIntervalSecPointer
            }
        }

        if let _will = self.will {
            raw_connect_options.will = _will.withCPointer { willPointer in return willPointer }
        }

        // User Properties
        if let _userProperties = userProperties {
            raw_connect_options.user_property_count = _userProperties.count
            raw_connect_options.user_properties = _userProperties.withCMqttUserProperties { cUserProperties in
                return UnsafePointer<aws_mqtt5_user_property>(cUserProperties)
            }
        }

        // TODO: CALLBACKS, THE CALLBACKS WILL COME WITH THE NEXT PR

        return withByteCursorFromStrings(clientId) { cClientId in
            raw_connect_options.client_id = cClientId

            return withOptionalByteCursorPointerFromString(self.username,
                                                           self.password) { cUsernamePointer, cPasswordPointer in
                raw_connect_options.username = cUsernamePointer
                raw_connect_options.password = cPasswordPointer
                return body(raw_connect_options)
            }
        }
    }
}

/// Configuration for the creation of MQTT5 clients
public class MqttClientOptions {
    /// Host name of the MQTT server to connect to.
    public let hostName: String

    /// Network port of the MQTT server to connect to.
    public let port: UInt32

    /// The Client bootstrap used
    public let bootstrap: ClientBootstrap

    /// The socket properties of the underlying MQTT connections made by the client or None if defaults are used.
    public let socketOptions: SocketOptions

    /// The TLS context for secure socket connections. If None, then a plaintext connection will be used.
    public let tlsCtx: TLSContext

    /// The (tunneling) HTTP proxy usage when establishing MQTT connections
    public let httpProxyOptions: HTTPProxyOptions?

    // TODO WebSocket implementation
    /// This callback allows a custom transformation of the HTTP request that acts as the websocket handshake. Websockets will be used if this is set to a valid transformation callback.  To use websockets but not perform a transformation, just set this as a trivial completion callback.  If None, the connection will be made with direct MQTT.
    // public let websocketHandshakeTransform: Callable[[WebsocketHandshakeTransformArgs], None] = None

    /// All configurable options with respect to the CONNECT packet sent by the client, including the will. These connect properties will be used for every connection attempt made by the client.
    public let connectOptions: MqttConnectOptions?

    /// How the MQTT5 client should behave with respect to MQTT sessions.
    public let sessionBehavior: ClientSessionBehaviorType?

    /// The additional controls for client behavior with respect to operation validation and flow control; these checks go beyond the base MQTT5 spec to respect limits of specific MQTT brokers.
    public let extendedValidationAndFlowControlOptions: ExtendedValidationAndFlowControlOptions?

    /// Returns how disconnects affect the queued and in-progress operations tracked by the client.  Also controls how new operations are handled while the client is not connected.  In particular, if the client is not connected, then any operation that would be failed on disconnect (according to these rules) will also be rejected.
    public let offlineQueueBehavior: ClientOperationQueueBehaviorType?

    /// How the reconnect delay is modified in order to smooth out the distribution of reconnection attempt timepoints for a large set of reconnecting clients.
    public let retryJitterMode: ExponentialBackoffJitterMode?

    /// The minimum amount of time to wait to reconnect after a disconnect. Exponential backoff is performed with jitter after each connection failure.
    public let minReconnectDelayMs: UInt64?

    /// The maximum amount of time to wait to reconnect after a disconnect.  Exponential backoff is performed with jitter after each connection failure.
    public let maxReconnectDelayMs: UInt64?

    /// The amount of time that must elapse with an established connection before the reconnect delay is reset to the minimum. This helps alleviate bandwidth-waste in fast reconnect cycles due to permission failures on operations.
    public let minConnectedTimeToResetReconnectDelayMs: UInt64?

    /// The time interval to wait after sending a PINGREQ for a PINGRESP to arrive. If one does not arrive, the client will close the current connection.
    public let pingTimeoutMs: UInt32?

    /// The time interval to wait after sending a CONNECT request for a CONNACK to arrive.  If one does not arrive, the connection will be shut down.
    public let connackTimeoutMs: UInt32?

    /// The time interval to wait for an ack after sending a QoS 1+ PUBLISH, SUBSCRIBE, or UNSUBSCRIBE before failing the operation.
    public let ackTimeoutSec: UInt32?

    /// All configurable options with respect to client topic aliasing behavior.
    public let topicAliasingOptions: TopicAliasingOptions?

    /// Callback for all publish packets received by client.
    public let onPublishReceivedFn: OnPublishReceived?

    /// Callback for Lifecycle Event Stopped.
    public let onLifecycleEventStoppedFn: OnLifecycleEventStopped?

    /// Callback for Lifecycle Event Attempting Connect.
    public let onLifecycleEventAttemptingConnectFn: OnLifecycleEventAttemptingConnect?

    /// Callback for Lifecycle Event Connection Success.
    public let onLifecycleEventConnectionSuccessFn: OnLifecycleEventConnectionSuccess?

    /// Callback for Lifecycle Event Connection Failure.
    public let onLifecycleEventConnectionFailureFn: OnLifecycleEventConnectionFailure?

    /// Callback for Lifecycle Event Disconnection.
    public let onLifecycleEventDisconnectionFn: OnLifecycleEventDisconnection?

    public init (
        hostName: String,
        port: UInt32,
        bootstrap: ClientBootstrap,
        socketOptions: SocketOptions,
        tlsCtx: TLSContext,
        httpProxyOptions: HTTPProxyOptions? = nil,
        connectOptions: MqttConnectOptions? = nil,
        sessionBehavior: ClientSessionBehaviorType? = nil,
        extendedValidationAndFlowControlOptions: ExtendedValidationAndFlowControlOptions? = nil,
        offlineQueueBehavior: ClientOperationQueueBehaviorType? = nil,
        retryJitterMode: ExponentialBackoffJitterMode? = nil,
        minReconnectDelayMs: UInt64? = nil,
        maxReconnectDelayMs: UInt64? = nil,
        minConnectedTimeToResetReconnectDelayMs: UInt64? = nil,
        pingTimeoutMs: UInt32? = nil,
        connackTimeoutMs: UInt32? = nil,
        ackTimeoutSec: UInt32? = nil,
        topicAliasingOptions: TopicAliasingOptions? = nil,
        onPublishReceivedFn: OnPublishReceived? = nil,
        onLifecycleEventStoppedFn: OnLifecycleEventStopped? = nil,
        onLifecycleEventAttemptingConnectFn: OnLifecycleEventAttemptingConnect? = nil,
        onLifecycleEventConnectionSuccessFn: OnLifecycleEventConnectionSuccess? = nil,
        onLifecycleEventConnectionFailureFn: OnLifecycleEventConnectionFailure? = nil,
        onLifecycleEventDisconnectionFn: OnLifecycleEventDisconnection? = nil) {

        self.hostName = hostName
        self.port = port
        self.bootstrap = bootstrap
        self.socketOptions = socketOptions
        self.tlsCtx = tlsCtx
        self.httpProxyOptions = httpProxyOptions
        self.connectOptions = connectOptions
        self.sessionBehavior = sessionBehavior
        self.extendedValidationAndFlowControlOptions = extendedValidationAndFlowControlOptions
        self.offlineQueueBehavior = offlineQueueBehavior
        self.retryJitterMode = retryJitterMode
        self.minReconnectDelayMs = minReconnectDelayMs
        self.maxReconnectDelayMs = maxReconnectDelayMs
        self.minConnectedTimeToResetReconnectDelayMs = minConnectedTimeToResetReconnectDelayMs
        self.pingTimeoutMs = pingTimeoutMs
        self.connackTimeoutMs = connackTimeoutMs
        self.ackTimeoutSec = ackTimeoutSec
        self.topicAliasingOptions = topicAliasingOptions
        self.onPublishReceivedFn = onPublishReceivedFn
        self.onLifecycleEventStoppedFn = onLifecycleEventStoppedFn
        self.onLifecycleEventAttemptingConnectFn = onLifecycleEventAttemptingConnectFn
        self.onLifecycleEventConnectionSuccessFn = onLifecycleEventConnectionSuccessFn
        self.onLifecycleEventConnectionFailureFn = onLifecycleEventConnectionFailureFn
        self.onLifecycleEventDisconnectionFn = onLifecycleEventDisconnectionFn
    }
}

/// Internal Classes
/// Callback core for event loop callbacks
class MqttShutdownCallbackCore {
    let onPublishReceivedCallback: OnPublishReceived?
    let onLifecycleEventStoppedCallback: OnLifecycleEventStopped?
    let onLifecycleEventAttemptingConnect: OnLifecycleEventAttemptingConnect?
    let onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess?
    let onLifecycleEventConnectionFailure: OnLifecycleEventConnectionFailure?

    init(onPublishReceivedCallback: OnPublishReceived?,
         onLifecycleEventStoppedCallback: OnLifecycleEventStopped?,
         onLifecycleEventAttemptingConnect: OnLifecycleEventAttemptingConnect?,
         onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess?,
         onLifecycleEventConnectionFailure: OnLifecycleEventConnectionFailure?,
         data: AnyObject? = nil) {
        if let onPublishReceivedCallback = onPublishReceivedCallback {
            self.onPublishReceivedCallback = onPublishReceivedCallback
        } else {
            /// Pass an empty callback to make manual reference counting easier and avoid null checks.
            self.onPublishReceivedCallback = { (_) -> Void in return }
        }

        if let onLifecycleEventStoppedCallback = onLifecycleEventStoppedCallback {
            self.onLifecycleEventStoppedCallback = onLifecycleEventStoppedCallback
        } else {
            /// Pass an empty callback to make manual reference counting easier and avoid null checks.
            self.onLifecycleEventStoppedCallback = { (_) -> Void in return}
        }

        if let onLifecycleEventAttemptingConnect = onLifecycleEventAttemptingConnect {
            self.onLifecycleEventAttemptingConnect = onLifecycleEventAttemptingConnect
        } else {
            /// Pass an empty callback to make manual reference counting easier and avoid null checks.
            self.onLifecycleEventAttemptingConnect = { (_) -> Void in return}
        }

        if let onLifecycleEventConnectionSuccess = onLifecycleEventConnectionSuccess {
            self.onLifecycleEventConnectionSuccess = onLifecycleEventConnectionSuccess
        } else {
            /// Pass an empty callback to make manual reference counting easier and avoid null checks.
            self.onLifecycleEventConnectionSuccess = { (_) -> Void in return}
        }

        if let onLifecycleEventConnectionFailure = onLifecycleEventConnectionFailure {
            self.onLifecycleEventConnectionFailure = onLifecycleEventConnectionFailure
        } else {
            /// Pass an empty callback to make manual reference counting easier and avoid null checks.
            self.onLifecycleEventConnectionFailure = { (_) -> Void in return}
        }
    }

    func getMqtt5TerminationCallbackOptions() {

    }

    func release() {
        Unmanaged<MqttShutdownCallbackCore>.passUnretained(self).release()
    }
}
