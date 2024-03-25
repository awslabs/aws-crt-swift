///  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
///  SPDX-License-Identifier: Apache-2.0.

import Foundation

/// Mqtt5 User Property
public class UserProperty {

    /// Property name
    public let name: String

    /// Property value
    public let value: String

    public init (name: String, value: String) {
        self.name = name
        self.value = value
    }
}

/// Data model of an `MQTT5 PUBLISH <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901100>`_ packet
public class PublishPacket {

    /// The payload of the publish message in a byte buffer format
    public let payload: Data?

    /// The MQTT quality of service associated with this PUBLISH packet.
    public let qos: QoS

    /// The topic associated with this PUBLISH packet.
    public let topic: String

    /// True if this is a retained message, false otherwise.
    public let retain: Bool

    /// Property specifying the format of the payload data. The mqtt5 client does not enforce or use this value in a meaningful way.
    public let payloadFormatIndicator: PayloadFormatIndicator?

    /// Sent publishes - indicates the maximum amount of time in whole seconds allowed to elapse for message delivery before the server should instead delete the message (relative to a recipient). Received publishes - indicates the remaining amount of time (from the server's perspective) before the message would have been deleted relative to the subscribing client. If left None, indicates no expiration timeout.
    public let messageExpiryInterval: TimeInterval?

    /// An integer value that is used to identify the Topic instead of using the Topic Name.  On outbound publishes, this will only be used if the outbound topic aliasing behavior has been set to Manual.
    public let topicAlias: UInt16?

    /// Opaque topic string intended to assist with request/response implementations.  Not internally meaningful to MQTT5 or this client.
    public let responseTopic: String?

    /// Opaque binary data used to correlate between publish messages, as a potential method for request-response implementation.  Not internally meaningful to MQTT5.
    public let correlationData: String? // Unicode objects are converted to C Strings using 'utf-8' encoding

    /// The subscription identifiers of all the subscriptions this message matched.
    public let subscriptionIdentifiers: [UInt32]? // ignore attempts to set but provide in received packets

    /// Property specifying the content type of the payload.  Not internally meaningful to MQTT5.
    public let contentType: String?

    /// Array of MQTT5 user properties included with the packet.
    public let userProperties: [UserProperty]?

    public init(qos: QoS,
         topic: String,
         payload: Data? = nil,
         retain: Bool = false,
         payloadFormatIndicator: PayloadFormatIndicator? = nil,
         messageExpiryInterval: TimeInterval? = nil,
         topicAlias: UInt16? = nil,
         responseTopic: String? = nil,
         correlationData: String? = nil,
         subscriptionIdentifiers: [UInt32]? = nil,
         contentType: String? = nil,
         userProperties: [UserProperty]? = nil) {

        self.qos = qos
        self.topic = topic
        self.payload = payload
        self.retain = retain
        self.payloadFormatIndicator = payloadFormatIndicator
        self.messageExpiryInterval = messageExpiryInterval
        self.topicAlias = topicAlias
        self.responseTopic = responseTopic
        self.correlationData = correlationData
        self.subscriptionIdentifiers = subscriptionIdentifiers
        self.contentType = contentType
        self.userProperties = userProperties
    }

    /// Get payload converted to a utf8 String
    public func payloadAsString() -> String {
        if let data = payload {
            return String(data: data, encoding: .utf8) ?? ""
        }
        return ""
    }
}

/// "Data model of an `MQTT5 PUBACK <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901121>`_ packet
public class PubackPacket {

    /// Success indicator or failure reason for the associated PUBLISH packet.
    public let reasonCode: PubackReasonCode

    /// Additional diagnostic information about the result of the PUBLISH attempt.
    public let reasonString: String?

    /// Array of MQTT5 user properties included with the packet.
    public let userProperties: [UserProperty]?

    public init (reasonCode: PubackReasonCode,
          reasonString: String? = nil,
          userProperties: [UserProperty]? = nil) {
        self.reasonCode = reasonCode
        self.reasonString = reasonString
        self.userProperties = userProperties
    }
}

/// Configures a single subscription within a Subscribe operation
public class Subscription {

    /// The topic filter to subscribe to
    public let topicFilter: String

    /// The maximum QoS on which the subscriber will accept publish messages
    public let qos: QoS

    /// Whether the server will not send publishes to a client when that client was the one who sent the publish
    public let noLocal: Bool?

    /// Whether messages sent due to this subscription keep the retain flag preserved on the message
    public let retainAsPublished: Bool?

    /// Whether retained messages on matching topics be sent in reaction to this subscription
    public let retainHandlingType: RetainHandlingType?

    public init (topicFilter: String,
          qos: QoS,
          noLocal: Bool? = nil,
          retainAsPublished: Bool? = nil,
          retainHandlingType: RetainHandlingType? = nil) {
        self.topicFilter = topicFilter
        self.qos = qos
        self.noLocal = noLocal
        self.retainAsPublished = retainAsPublished
        self.retainHandlingType = retainHandlingType
    }
}

/// Data model of an `MQTT5 SUBSCRIBE <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901161>`_ packet.
public class SubscribePacket {

    /// Array of topic filters that the client wishes to listen to
    public let subscriptions: [Subscription]

    /// The positive int to associate with all topic filters in this request.  Publish packets that match a subscription in this request should include this identifier in the resulting message.
    public let subscriptionIdentifier: UInt32?

    /// Array of MQTT5 user properties included with the packet.
    public let userProperties: [UserProperty]?

    public init (subscriptions: [Subscription],
          subscriptionIdentifier: UInt32? = nil,
          userProperties: [UserProperty]? = nil) {
          self.subscriptions = subscriptions
          self.subscriptionIdentifier = subscriptionIdentifier
          self.userProperties = userProperties
    }

    // Allow a SubscribePacket to be created directly using a topic filter and QoS
    public convenience init (topicFilter: String,
                      qos: QoS,
                      subscriptionIdentifier: UInt32? = nil,
                      userProperties: [UserProperty]? = nil) {
        self.init(subscriptions: [Subscription(topicFilter: topicFilter, qos: qos)],
            subscriptionIdentifier: subscriptionIdentifier,
            userProperties: userProperties)
    }

    // Allow a SubscribePacket to be created directly using a single Subscription
    public convenience init (subscription: Subscription,
                      subscriptionIdentifier: UInt32? = nil,
                      userProperties: [UserProperty]? = nil) {
        self.init(subscriptions: [subscription],
            subscriptionIdentifier: subscriptionIdentifier,
            userProperties: userProperties)
    }
}

/// Data model of an `MQTT5 SUBACK <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901171>`_ packet.
public class SubackPacket {

    /// Array of reason codes indicating the result of each individual subscription entry in the associated SUBSCRIBE packet.
    public let reasonCodes: [SubackReasonCode]

    /// Additional diagnostic information about the result of the SUBSCRIBE attempt.
    public let reasonString: String?

    /// Array of MQTT5 user properties included with the packet.
    public let userProperties: [UserProperty]?

    public init (reasonCodes: [SubackReasonCode],
          reasonString: String? = nil,
          userProperties: [UserProperty]? = nil) {
        self.reasonCodes = reasonCodes
        self.reasonString = reasonString
        self.userProperties = userProperties
    }
}

/// Data model of an `MQTT5 UNSUBSCRIBE <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc384800445>`_ packet.
public class UnsubscribePacket {

    /// Array of topic filters that the client wishes to unsubscribe from.
    public let topicFilters: [String]

    /// Array of MQTT5 user properties included with the packet.
    public let userProperties: [UserProperty]?

    public init (topicFilters: [String],
          userProperties: [UserProperty]? = nil) {
        self.topicFilters = topicFilters
        self.userProperties = userProperties
    }

    // Allow an UnsubscribePacket to be created directly using a single topic filter
    public convenience init (topicFilter: String,
                      userProperties: [UserProperty]? = nil) {
            self.init(topicFilters: [topicFilter],
                userProperties: userProperties)
        }
}

/// Data model of an `MQTT5 UNSUBACK <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc471483687>`_ packet.
public class UnsubackPacket {

    /// Array of reason codes indicating the result of unsubscribing from each individual topic filter entry in the associated UNSUBSCRIBE packet.
    public let reasonCodes: [DisconnectReasonCode]

    /// Additional diagnostic information about the result of the UNSUBSCRIBE attempt.
    public let reasonString: String?

    /// Array of MQTT5 user properties included with the packet.
    public let userProperties: [UserProperty]?

    public init (reasonCodes: [DisconnectReasonCode],
          reasonString: String? = nil,
          userProperties: [UserProperty]? = nil) {
        self.reasonCodes = reasonCodes
        self.reasonString = reasonString
        self.userProperties = userProperties
    }
}

/// Data model of an `MQTT5 DISCONNECT <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901205>`_ packet.
public class DisconnectPacket {

    /// Value indicating the reason that the sender is closing the connection
    public let reasonCode: DisconnectReasonCode

    /// A change to the session expiry interval in whole seconds negotiated at connection time as part of the disconnect.  Only valid for DISCONNECT packets sent from client to server.  It is not valid to attempt to change session expiry from zero to a non-zero value.
    public let sessionExpiryInterval: TimeInterval?

    /// Additional diagnostic information about the reason that the sender is closing the connection
    public let reasonString: String?

    /// Property indicating an alternate server that the client may temporarily or permanently attempt to connect to instead of the configured endpoint.  Will only be set if the reason code indicates another server may be used (ServerMoved, UseAnotherServer).
    public let serverReference: String?

    /// Array of MQTT5 user properties included with the packet.
    public let userProperties: [UserProperty]?

    public init (reasonCode: DisconnectReasonCode = DisconnectReasonCode.normalDisconnection,
          sessionExpiryInterval: TimeInterval? = nil,
          reasonString: String? = nil,
          serverReference: String? = nil,
          userProperties: [UserProperty]? = nil) {
            self.reasonCode = reasonCode
            self.sessionExpiryInterval = sessionExpiryInterval
            self.reasonString = reasonString
            self.serverReference = serverReference
            self.userProperties = userProperties
        }
}

/// Data model of an `MQTT5 CONNACK <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901074>`_ packet.
public class ConnackPacket {

    /// True if the client rejoined an existing session on the server, false otherwise.
    public let sessionPresent: Bool

    /// Indicates either success or the reason for failure for the connection attempt.
    public let reasonCode: ConnectReasonCode

    /// A time interval, in whole seconds, that the server will persist this connection's MQTT session state for.  If present, this value overrides any session expiry specified in the preceding CONNECT packet.
    public let sessionExpiryInterval: TimeInterval?

    /// The maximum amount of in-flight QoS 1 or 2 messages that the server is willing to handle at once. If omitted or None, the limit is based on the valid MQTT packet id space (65535).
    public let receiveMaximum: UInt16?

    /// The maximum message delivery quality of service that the server will allow on this connection.
    public let maximumQos: QoS?

    /// Indicates whether the server supports retained messages.  If None, retained messages are supported.
    public let retainAvailable: Bool?

    /// Specifies the maximum packet size, in bytes, that the server is willing to accept.  If None, there is no limit beyond what is imposed by the MQTT spec itself.
    public let maximumPacketSize: UInt32?

    /// Specifies a client identifier assigned to this connection by the server.  Only valid when the client id of the preceding CONNECT packet was left empty.
    public let assignedClientIdentifier: String?

    /// The maximum allowed value for topic aliases in outbound publish packets.  If 0 or None, then outbound topic aliasing is not allowed.
    public let topicAliasMaximum: UInt16?

    /// Additional diagnostic information about the result of the connection attempt.
    public let reasonString: String?

    /// Array of MQTT5 user properties included with the packet.
    public let userProperties: [UserProperty]?

    /// Indicates whether the server supports wildcard subscriptions.  If None, wildcard subscriptions are supported.
    public let wildcardSubscriptionsAvailable: Bool?

    /// Indicates whether the server supports subscription identifiers.  If None, subscription identifiers are supported.
    public let subscriptionIdentifiersAvailable: Bool?

    /// Indicates whether the server supports shared subscription topic filters.  If None, shared subscriptions are supported.
    public let sharedSubscriptionAvailable: Bool?

    /// Server-requested override of the keep alive interval, in whole seconds.  If None, the keep alive value sent by the client should be used.
    public let serverKeepAlive: TimeInterval?

    /// A value that can be used in the creation of a response topic associated with this connection. MQTT5-based request/response is outside the purview of the MQTT5 spec and this client.
    public let responseInformation: String?

    /// Property indicating an alternate server that the client may temporarily or permanently attempt to connect to instead of the configured endpoint.  Will only be set if the reason code indicates another server may be used (ServerMoved, UseAnotherServer).
    public let serverReference: String?

    public init (sessionPresent: Bool,
          reasonCode: ConnectReasonCode,
          sessionExpiryInterval: TimeInterval? = nil,
          receiveMaximum: UInt16? = nil,
          maximumQos: QoS? = nil,
          retainAvailable: Bool? = nil,
          maximumPacketSize: UInt32? = nil,
          assignedClientIdentifier: String? = nil,
          topicAliasMaximum: UInt16? = nil,
          reasonString: String? = nil,
          userProperties: [UserProperty]? = nil,
          wildcardSubscriptionsAvailable: Bool? = nil,
          subscriptionIdentifiersAvailable: Bool? = nil,
          sharedSubscriptionAvailable: Bool? = nil,
          serverKeepAlive: TimeInterval? = nil,
          responseInformation: String? = nil,
          serverReference: String? = nil) {
        self.sessionPresent = sessionPresent
        self.reasonCode = reasonCode

        self.sessionExpiryInterval = sessionExpiryInterval
        self.receiveMaximum = receiveMaximum
        self.maximumQos = maximumQos
        self.retainAvailable = retainAvailable
        self.maximumPacketSize = maximumPacketSize
        self.assignedClientIdentifier = assignedClientIdentifier
        self.topicAliasMaximum = topicAliasMaximum
        self.reasonString = reasonString
        self.userProperties = userProperties
        self.wildcardSubscriptionsAvailable = wildcardSubscriptionsAvailable
        self.subscriptionIdentifiersAvailable = subscriptionIdentifiersAvailable
        self.sharedSubscriptionAvailable = sharedSubscriptionAvailable
        self.serverKeepAlive = serverKeepAlive
        self.responseInformation = responseInformation
        self.serverReference = serverReference
    }
}
