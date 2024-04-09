///  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
///  SPDX-License-Identifier: Apache-2.0.

import Foundation
import AwsCMqtt

/// Mqtt5 User Property
public class UserProperty: CStruct {

    /// Property name
    public let name: String

    /// Property value
    public let value: String

    public init (name: String, value: String) {
        self.name = name
        self.value = value
    }

    typealias RawType = aws_mqtt5_user_property
    func withCStruct<Result>(_ body: (aws_mqtt5_user_property) -> Result) -> Result {
        var rawUserProperty = aws_mqtt5_user_property()
        return withByteCursorFromStrings(name, value) { cNameCursor, cValueCursor in
            aws_byte_buf_clean_up(&name_buffer)
            aws_byte_buf_clean_up(&value_buffer)
            aws_byte_buf_init_copy_from_cursor(&name_buffer, allocator, cNameCursor)
            aws_byte_buf_init_copy_from_cursor(&value_buffer, allocator, cValueCursor)
            rawUserProperty.name = aws_byte_cursor_from_buf(&name_buffer)
            rawUserProperty.value = aws_byte_cursor_from_buf(&value_buffer)
            return body(rawUserProperty)
        }
    }

    // We keep a memory of the buffer storage in the class, and release it on
    // destruction
    private var name_buffer: aws_byte_buf = aws_byte_buf()
    private var value_buffer: aws_byte_buf = aws_byte_buf()
    deinit {
        aws_byte_buf_clean_up(&name_buffer)
        aws_byte_buf_clean_up(&value_buffer)
    }
}

extension Array where Element == UserProperty {
    func withCMqttUserProperties<Result>(_ body: (OpaquePointer) throws -> Result) rethrows -> Result {
        var array_list: UnsafeMutablePointer<aws_array_list> = allocator.allocate(capacity: 1)
        defer {
            aws_array_list_clean_up(array_list)
            allocator.release(array_list)
        }
        guard aws_array_list_init_dynamic(
            array_list,
            allocator.rawValue,
            count,
            MemoryLayout<aws_mqtt5_user_property>.size) == AWS_OP_SUCCESS else {
            fatalError("Unable to initialize array of user properties")
        }
        forEach {
            $0.withCPointer {
                // `aws_array_list_push_back` will do a memory copy of $0 into array_list
                guard aws_array_list_push_back(array_list, $0) == AWS_OP_SUCCESS else {
                    fatalError("Unable to add user property")
                }
            }
        }
        return try body(OpaquePointer(array_list.pointee.data))
    }
}

/// Help function to handle Optional UserProperty Array into c pointer
func withOptionalUserPropertyArray<Result>(
    of array: Array<UserProperty>?,
    _ body: (OpaquePointer?) throws -> Result) rethrows -> Result {
    guard let _array = array else {
        return try body(nil)
    }
    return try _array.withCMqttUserProperties { opaquePointer in
        return try body(opaquePointer)
    }
}

/// Convert a native UserProperty pointer into a Swift [UserProperty]?
func convertOptionalUserProperties(count: size_t, userPropertiesPointer: UnsafePointer<aws_mqtt5_user_property>?) -> [UserProperty]? {

    guard let validPointer = userPropertiesPointer, count > 0 // swiftlint:disable:this empty_count
    else { return nil }

    var userProperties: [UserProperty] = []

    for i in 0..<count {
        let property = validPointer.advanced(by: Int(i)).pointee
        let name = property.name.toString()
        let value = property.value.toString()

        let userProperty = UserProperty(name: name, value: value)
        userProperties.append(userProperty)
    }

    return userProperties
}

/// Data model of an `MQTT5 PUBLISH <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901100>`_ packet
public class PublishPacket: CStruct {

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

    typealias RawType = aws_mqtt5_packet_publish_view
    func withCStruct<Result>(_ body: (aws_mqtt5_packet_publish_view) -> Result) -> Result {
        var raw_publish_view = aws_mqtt5_packet_publish_view()

        raw_publish_view.qos = aws_mqtt5_qos(UInt32(qos.rawValue))
        raw_publish_view.retain = retain
        return topic.withByteCursor { topicCustor in
            raw_publish_view.topic =  topicCustor
            return withOptionalAWSByteCursorFromData(to: payload) { cByteCursor in
                raw_publish_view.payload = cByteCursor

                let _payloadFormatIndicatorInt: aws_mqtt5_payload_format_indicator? =
                                                                    payloadFormatIndicator?.rawValue ?? nil
                let _messageExpiryInterval: UInt32? = try? messageExpiryInterval?.secondUInt32() ?? nil

                return withOptionalUnsafePointers(
                    _payloadFormatIndicatorInt,
                    topicAlias,
                    _messageExpiryInterval) { payloadPointer, topicAliasPointer, messageExpiryIntervalPointer in
                    if let _payloadPointer = payloadPointer {
                        raw_publish_view.payload_format = _payloadPointer
                    }

                    if let _messageExpiryIntervalPointer = messageExpiryIntervalPointer {
                        raw_publish_view.message_expiry_interval_seconds = _messageExpiryIntervalPointer
                    }

                    if let _topicAliasPointer = topicAliasPointer {
                        raw_publish_view.topic_alias = _topicAliasPointer
                    }

                    return withOptionalArrayRawPointer(of: subscriptionIdentifiers) { subscriptionPointer in

                        if let _subscriptionPointer = subscriptionPointer {
                            raw_publish_view.subscription_identifiers = _subscriptionPointer
                            raw_publish_view.subscription_identifier_count = subscriptionIdentifiers!.count
                        }

                        return withOptionalUserPropertyArray(
                            of: userProperties) { userPropertyPointer in
                            if let _userPropertyPointer = userPropertyPointer {
                                raw_publish_view.user_property_count = userProperties!.count
                                raw_publish_view.user_properties =
                                    UnsafePointer<aws_mqtt5_user_property>(_userPropertyPointer)
                            }
                            return withOptionalByteCursorPointerFromString(
                            responseTopic,
                            correlationData,
                            contentType) { cResponseTopic, cCorrelationData, cContentType in
                                raw_publish_view.content_type = cContentType
                                raw_publish_view.correlation_data = cCorrelationData
                                raw_publish_view.response_topic = cResponseTopic

                                return body(raw_publish_view)
                            }
                        }
                    }
                }
            }
        }
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
public class DisconnectPacket: CStruct {

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

    typealias RawType = aws_mqtt5_packet_disconnect_view
    func withCStruct<Result>(_ body: (aws_mqtt5_packet_disconnect_view) -> Result) -> Result {
        var raw_disconnect_view = aws_mqtt5_packet_disconnect_view()

        raw_disconnect_view.reason_code = aws_mqtt5_disconnect_reason_code(UInt32(reasonCode.rawValue))

        let _sessionExpiryInterval = try? sessionExpiryInterval?.secondUInt32() ?? nil

        return withOptionalUnsafePointer(to: _sessionExpiryInterval) { sessionExpiryIntervalPointer in

            if let _sessionExpiryIntervalPointer = sessionExpiryIntervalPointer {
                raw_disconnect_view.session_expiry_interval_seconds = _sessionExpiryIntervalPointer
            }

            return withOptionalUserPropertyArray(
                of: userProperties) { userPropertyPointer in

                if let _userPropertyPointer = userPropertyPointer {
                    raw_disconnect_view.user_property_count = userProperties!.count
                    raw_disconnect_view.user_properties =
                        UnsafePointer<aws_mqtt5_user_property>(_userPropertyPointer)
                }

                return withOptionalByteCursorPointerFromStrings(
                    reasonString,
                    serverReference) { cReasonString, cServerReference in
                        raw_disconnect_view.reason_string = cReasonString
                        raw_disconnect_view.server_reference = cServerReference
                        return body(raw_disconnect_view)
                    }
            }
        }
    }

    static func convertFromNative(_ from: UnsafePointer<aws_mqtt5_packet_disconnect_view>?) -> DisconnectPacket? {
        if let from = from {
            guard let reasonCode = DisconnectReasonCode(rawValue: Int(from.pointee.reason_code.rawValue))
            else { fatalError("DisconnectPacket from native missing a reason code.") }

            let sessionExpiryInterval = convertOptionalUInt32(from.pointee.session_expiry_interval_seconds)
            let sessionExpiryIntervalSeconds: TimeInterval? = sessionExpiryInterval.map { TimeInterval($0) }
            let reasonString = convertAwsByteCursorToOptionalString(from.pointee.reason_string)
            let serverReference = convertAwsByteCursorToOptionalString(from.pointee.reason_string)
            let userProperties = convertOptionalUserProperties(
                count: from.pointee.user_property_count,
                userPropertiesPointer: from.pointee.user_properties)

            let disconnectPacket = DisconnectPacket(
                reasonCode: reasonCode,
                sessionExpiryInterval: sessionExpiryIntervalSeconds,
                reasonString: reasonString,
                serverReference: serverReference,
                userProperties: userProperties
            )
            return disconnectPacket
        }
        return nil
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

    static func convertFromNative(_ from: UnsafePointer<aws_mqtt5_packet_connack_view>?) -> ConnackPacket? {

        if let from = from {

            let sessionPresent = from.pointee.session_present
            let reasonCode = ConnectReasonCode(rawValue: Int(from.pointee.reason_code.rawValue)) ?? .unspecifiedError
            let sessionExpiryInterval = (from.pointee.session_expiry_interval?.pointee).map { TimeInterval($0) }
            let receiveMaximum = convertOptionalUInt16(from.pointee.receive_maximum)

            var maximumQos: QoS? = nil
            if let maximumQosValue = from.pointee.maximum_qos {
                let maximumQoSNativeValue = maximumQosValue.pointee.rawValue
                maximumQos = QoS(rawValue: Int(maximumQoSNativeValue))
            }

            let retainAvailable = convertOptionalBool(from.pointee.retain_available)
            let maximumPacketSize = convertOptionalUInt32(from.pointee.maximum_packet_size)
            let assignedClientIdentifier = convertAwsByteCursorToOptionalString(from.pointee.assigned_client_identifier)
            let topicAliasMaximum = convertOptionalUInt16(from.pointee.topic_alias_maximum)
            let reasonString = convertAwsByteCursorToOptionalString(from.pointee.reason_string)
            let wildcardSubscriptionsAvailable = convertOptionalBool(from.pointee.wildcard_subscriptions_available)
            let subscriptionIdentifiersAvailable = convertOptionalBool(from.pointee.subscription_identifiers_available)
            let sharedSubscriptionAvailable = convertOptionalBool(from.pointee.shared_subscriptions_available)
            let serverKeepAlive = convertOptionalUInt16(from.pointee.server_keep_alive)
            let serverKeepAliveInSeconds: TimeInterval? = serverKeepAlive.map { TimeInterval($0) }
            let responseInformation = convertAwsByteCursorToOptionalString(from.pointee.response_information)
            let serverReference = convertAwsByteCursorToOptionalString(from.pointee.server_reference)
            let userProperties = convertOptionalUserProperties(
                count: from.pointee.user_property_count,
                userPropertiesPointer: from.pointee.user_properties)

            let connackPacket = ConnackPacket(
                sessionPresent: sessionPresent,
                reasonCode: reasonCode,
                sessionExpiryInterval: sessionExpiryInterval,
                receiveMaximum: receiveMaximum,
                maximumQos: maximumQos,
                retainAvailable: retainAvailable,
                maximumPacketSize: maximumPacketSize,
                assignedClientIdentifier: assignedClientIdentifier,
                topicAliasMaximum: topicAliasMaximum,
                reasonString: reasonString,
                userProperties: userProperties,
                wildcardSubscriptionsAvailable: wildcardSubscriptionsAvailable,
                subscriptionIdentifiersAvailable: subscriptionIdentifiersAvailable,
                sharedSubscriptionAvailable: sharedSubscriptionAvailable,
                serverKeepAlive: serverKeepAliveInSeconds,
                responseInformation: responseInformation,
                serverReference: serverReference)

            return connackPacket
        }
        return nil
    }
}
