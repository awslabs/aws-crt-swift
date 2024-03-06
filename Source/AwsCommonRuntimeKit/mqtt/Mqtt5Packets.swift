///  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
///  SPDX-License-Identifier: Apache-2.0.

import Foundation

/// Mqtt5 User Property
public class UserProperty {

    /// Property name
    let name: String

    /// Property value
    let value: String

    init (name: String, value: String) {
        self.name = name
        self.value = value
    }
}

/// Data model of an `MQTT5 PUBLISH <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901100>`_ packet
public class PublishPacket {

    /// The payload of the publish message in a byte buffer format
    var payload: Data?

    /// The MQTT quality of service associated with this PUBLISH packet.
    var qos: QoS

    /// The topic associated with this PUBLISH packet.
    var topic: String

    /// True if this is a retained message, false otherwise.
    var retain: Bool = false

    /// Property specifying the format of the payload data. The mqtt5 client does not enforce or use this value in a meaningful way.
    var payloadFormatIndicator: PayloadFormatIndicator?

    /// Sent publishes - indicates the maximum amount of time allowed to elapse for message delivery before the server should instead delete the message (relative to a recipient). Received publishes - indicates the remaining amount of time (from the server's perspective) before the message would have been deleted relative to the subscribing client. If left None, indicates no expiration timeout.
    var messageExpiryIntervalSec: UInt32?

    /// An integer value that is used to identify the Topic instead of using the Topic Name.  On outbound publishes, this will only be used if the outbound topic aliasing behavior has been set to Manual.
    var topicAlias: UInt16?

    /// Opaque topic string intended to assist with request/response implementations.  Not internally meaningful to MQTT5 or this client.
    var responseTopic: String?

    /// Opaque binary data used to correlate between publish messages, as a potential method for request-response implementation.  Not internally meaningful to MQTT5.
    var correlationData: String? // Unicode objects are converted to C Strings using 'utf-8' encoding

    /// The subscription identifiers of all the subscriptions this message matched.
    var subscriptionIdentifiers: [UInt32]? // ignore attempts to set but provide in received packets

    /// Property specifying the content type of the payload.  Not internally meaningful to MQTT5.
    var contentType: String?

    /// Array of MQTT5 user properties included with the packet.
    var userProperties: [UserProperty]?

    init(qos: QoS, topic: String) {
        self.qos = qos
        self.topic = topic
    }

    /// Get payload converted to a utf8 String
    func payloadAsString() -> String? {
        if let data = payload {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}

/// "Data model of an `MQTT5 PUBACK <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901121>`_ packet
public class PubackPacket {

    /// Success indicator or failure reason for the associated PUBLISH packet.
    let reasonCode: PubackReasonCode

    /// Additional diagnostic information about the result of the PUBLISH attempt.
    var reasonString: String?

    /// Array of MQTT5 user properties included with the packet.
    var userProperties: [UserProperty]?

    init (reasonCode: PubackReasonCode) {
        self.reasonCode = reasonCode
    }
}

/// Configures a single subscription within a Subscribe operation
public class Subscription {

    /// The topic filter to subscribe to
    let topicFilter: String

    /// The maximum QoS on which the subscriber will accept publish messages
    let qos: QoS

    /// Whether the server will not send publishes to a client when that client was the one who sent the publish
    var noLocal: Bool?

    /// Whether messages sent due to this subscription keep the retain flag preserved on the message
    var retainAsPublished: Bool?

    /// Whether retained messages on matching topics be sent in reaction to this subscription
    var retainHandlingType: RetainHandlingType?

    init (topicFilter: String, qos: QoS) {
        self.topicFilter = topicFilter
        self.qos = qos
    }
}

/// Data model of an `MQTT5 SUBSCRIBE <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901161>`_ packet.
public class SubscribePacket {

    /// Array of topic filters that the client wishes to listen to
    var subscriptions: [Subscription]

    /// The positive int to associate with all topic filters in this request.  Publish packets that match a subscription in this request should include this identifier in the resulting message.
    var subscriptionIdentifier: UInt32?

    /// Array of MQTT5 user properties included with the packet.
    var userProperties: [UserProperty]?

    init (topicFilter: String, qos: QoS) {
        self.subscriptions = [Subscription(topicFilter: topicFilter, qos: qos)]
    }

    init (subscription: Subscription) {
        self.subscriptions = [subscription]
    }

    init (subscriptions: [Subscription]) {
        self.subscriptions = subscriptions
    }
}

/// Data model of an `MQTT5 SUBACK <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901171>`_ packet.
public class SubackPacket {

    /// Array of reason codes indicating the result of each individual subscription entry in the associated SUBSCRIBE packet.
    let reasonCodes: [SubackReasonCode]

    /// Additional diagnostic information about the result of the SUBSCRIBE attempt.
    var reasonString: String?

    /// Array of MQTT5 user properties included with the packet.
    var userProperties: [UserProperty]?

    init (reasonCodes: [SubackReasonCode]) {
        self.reasonCodes = reasonCodes
    }
}

/// Data model of an `MQTT5 UNSUBSCRIBE <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc384800445>`_ packet.
public class UnsubscribePacket {

    /// Array of topic filters that the client wishes to unsubscribe from.
    var topicFilters: [String]

    /// Array of MQTT5 user properties included with the packet.
    var userProperties: [UserProperty]?

    init (topicFilters: [String]) {
        self.topicFilters = topicFilters
    }
}

/// Data model of an `MQTT5 UNSUBACK <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc471483687>`_ packet.
public class UnsubackPacket {

    /// Array of reason codes indicating the result of unsubscribing from each individual topic filter entry in the associated UNSUBSCRIBE packet.
    let reasonCodes: [DisconnectReasonCode]

    /// Additional diagnostic information about the result of the UNSUBSCRIBE attempt.
    var reasonString: String?

    /// Array of MQTT5 user properties included with the packet.
    var userProperties: [UserProperty]?

    init (reasonCodes: [DisconnectReasonCode]) {
        self.reasonCodes = reasonCodes
    }
}

/// Data model of an `MQTT5 DISCONNECT <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901205>`_ packet.
public class DisconnectPacket {

    /// Value indicating the reason that the sender is closing the connection
    var reasonCode: DisconnectReasonCode = DisconnectReasonCode.normalDisconnection

    /// A change to the session expiry interval negotiated at connection time as part of the disconnect.  Only valid for DISCONNECT packets sent from client to server.  It is not valid to attempt to change session expiry from zero to a non-zero value.
    var sessionExpiryIntervalSec: UInt32?

    /// Additional diagnostic information about the reason that the sender is closing the connection
    var reasonString: String?

    /// Property indicating an alternate server that the client may temporarily or permanently attempt to connect to instead of the configured endpoint.  Will only be set if the reason code indicates another server may be used (ServerMoved, UseAnotherServer).
    var serverReference: String?

    /// Array of MQTT5 user properties included with the packet.
    var userProperties: [UserProperty]?

}

/// Data model of an `MQTT5 CONNACK <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901074>`_ packet.
public class ConnackPacket {

    /// True if the client rejoined an existing session on the server, false otherwise.
    let sessionPresent: Bool

    /// Indicates either success or the reason for failure for the connection attempt.
    let reasonCode: ConnectReasonCode

    /// A time interval, in seconds, that the server will persist this connection's MQTT session state for.  If present, this value overrides any session expiry specified in the preceding CONNECT packet.
    var sessionExpiryIntervalSec: UInt32?

    /// The maximum amount of in-flight QoS 1 or 2 messages that the server is willing to handle at once. If omitted or None, the limit is based on the valid MQTT packet id space (65535).
    var receiveMaximum: UInt16?

    /// The maximum message delivery quality of service that the server will allow on this connection.
    var maximumQos: QoS?

    /// Indicates whether the server supports retained messages.  If None, retained messages are supported.
    var retainAvailable: Bool?

    /// Specifies the maximum packet size, in bytes, that the server is willing to accept.  If None, there is no limit beyond what is imposed by the MQTT spec itself.
    var maximumPacketSize: UInt32?

    /// Specifies a client identifier assigned to this connection by the server.  Only valid when the client id of the preceding CONNECT packet was left empty.
    var assignedClientIdentifier: String?

    /// The maximum allowed value for topic aliases in outbound publish packets.  If 0 or None, then outbound topic aliasing is not allowed.
    var topicAliasMaximum: UInt16?

    /// Additional diagnostic information about the result of the connection attempt.
    var reasonString: String?

    /// Array of MQTT5 user properties included with the packet.
    var userProperties: [UserProperty]?

    /// Indicates whether the server supports wildcard subscriptions.  If None, wildcard subscriptions are supported.
    var wildcardSubscriptionsAvailable: Bool?

    /// Indicates whether the server supports subscription identifiers.  If None, subscription identifiers are supported.
    var subscriptionIdentifiersAvailable: Bool?

    /// Indicates whether the server supports shared subscription topic filters.  If None, shared subscriptions are supported.
    var sharedSubscriptionAvailable: Bool?

    /// Server-requested override of the keep alive interval, in seconds.  If None, the keep alive value sent by the client should be used.
    var serverKeepAliveSec: UInt16?

    /// A value that can be used in the creation of a response topic associated with this connection. MQTT5-based request/response is outside the purview of the MQTT5 spec and this client.
    var responseInformation: String?

    /// Property indicating an alternate server that the client may temporarily or permanently attempt to connect to instead of the configured endpoint.  Will only be set if the reason code indicates another server may be used (ServerMoved, UseAnotherServer).
    var serverReference: String?

    init (sessionPresent: Bool, reasonCode: ConnectReasonCode) {
        self.sessionPresent = sessionPresent
        self.reasonCode = reasonCode
    }
}
