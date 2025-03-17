///  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
///  SPDX-License-Identifier: Apache-2.0.

import Foundation
import AwsCHttp
import AwsCMqtt
import LibNative

/// Mqtt5 User Property
public class UserProperty: CStruct {

    /// Property name
    public let name: String

    /// Property value
    public let value: String

    public init (name: String, value: String) {
        self.name = name
        self.value = value

        withByteCursorFromStrings(self.name, self.value) { cNameCursor, cValueCursor in
            aws_byte_buf_clean_up(&name_buffer)
            aws_byte_buf_clean_up(&value_buffer)
            aws_byte_buf_init_copy_from_cursor(&name_buffer, allocator, cNameCursor)
            aws_byte_buf_init_copy_from_cursor(&value_buffer, allocator, cValueCursor)
        }
    }

    typealias RawType = aws_mqtt5_user_property
    func withCStruct<Result>(_ body: (aws_mqtt5_user_property) -> Result) -> Result {
        var rawUserProperty = aws_mqtt5_user_property()
        rawUserProperty.name = aws_byte_cursor_from_buf(&name_buffer)
        rawUserProperty.value = aws_byte_cursor_from_buf(&value_buffer)
        return body(rawUserProperty)
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
        let array_list: UnsafeMutablePointer<aws_array_list> = allocator.allocate(capacity: 1)
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

/// Helper function to convert Swift [UserProperty]? into a native aws_mqtt5_user_property pointer
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

/// Convert a native aws_mqtt5_user_property pointer into a Swift [UserProperty]?
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
    public let correlationData: Data? // Unicode objects are converted to C Strings using 'utf-8' encoding

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
                correlationData: Data? = nil,
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

    internal init(_ publish_view: UnsafePointer<aws_mqtt5_packet_publish_view>) {
        let publishView = publish_view.pointee
        self.qos = QoS(publishView.qos)
        self.topic = publishView.topic.toString()
        self.payload = Data(bytes: publishView.payload.ptr, count: publishView.payload.len)
        self.retain = publishView.retain
        self.payloadFormatIndicator = publishView.payload_format != nil ?
            PayloadFormatIndicator(publishView.payload_format.pointee) : nil
        self.messageExpiryInterval = (publishView.message_expiry_interval_seconds?.pointee).map { TimeInterval($0) }
        self.topicAlias = publishView.topic_alias?.pointee
        self.responseTopic = publishView.response_topic?.pointee.toString()
        self.correlationData = publishView.correlation_data != nil ?
            Data(bytes: publishView.correlation_data!.pointee.ptr, count: publishView.correlation_data!.pointee.len) : nil
        var identifier: [UInt32]? = []
        for i in 0..<publishView.subscription_identifier_count {
            let subscription_identifier: UInt32 = UInt32(publishView.subscription_identifiers.advanced(by: Int(i)).pointee)
            identifier?.append(subscription_identifier)
        }
        self.subscriptionIdentifiers = identifier
        self.contentType = publishView.content_type?.pointee.toString()
        self.userProperties = convertOptionalUserProperties(
            count: publishView.user_property_count,
            userPropertiesPointer: publishView.user_properties)
    }

    /// Get payload converted to a utf8 String
    public func payloadAsString() -> String? {
        if let payload {
            return String(data: payload, encoding: .utf8) ?? nil
        }
        return nil
    }

    func validateConversionToNative() throws {
        if let messageExpiryInterval {
            if messageExpiryInterval < 0 || messageExpiryInterval > Double(UInt32.max) {
                throw CommonRunTimeError.crtError(CRTError(code: AWS_ERROR_INVALID_ARGUMENT.rawValue,
                                                           context: "Invalid sessionExpiryInterval value"))
            }
        }
    }

    typealias RawType = aws_mqtt5_packet_publish_view
    func withCStruct<Result>(_ body: (aws_mqtt5_packet_publish_view) -> Result) -> Result {
        var raw_publish_view = aws_mqtt5_packet_publish_view()

        raw_publish_view.qos = self.qos.rawValue
        raw_publish_view.retain = retain
        return topic.withByteCursor { topicCustor in
            raw_publish_view.topic =  topicCustor
            return withAWSByteCursorFromOptionalData(to: payload) { cByteCursor in
                raw_publish_view.payload = cByteCursor

                let _payloadFormatIndicatorInt: aws_mqtt5_payload_format_indicator? = payloadFormatIndicator?.rawValue
                let _messageExpiryInterval: UInt32? = try? messageExpiryInterval?.secondUInt32()

                return withOptionalUnsafePointers(
                    _payloadFormatIndicatorInt,
                    topicAlias,
                    _messageExpiryInterval) { payloadPointer, topicAliasPointer, messageExpiryIntervalPointer in
                    raw_publish_view.payload_format = payloadPointer
                    raw_publish_view.message_expiry_interval_seconds = messageExpiryIntervalPointer
                    raw_publish_view.topic_alias = topicAliasPointer

                    return withOptionalArrayRawPointer(of: subscriptionIdentifiers) { subscriptionPointer in

                        if let subscriptionPointer,
                            let subscriptionCount = subscriptionIdentifiers?.count {
                            raw_publish_view.subscription_identifiers = subscriptionPointer
                            raw_publish_view.subscription_identifier_count = subscriptionCount
                        }

                        return withOptionalUserPropertyArray(
                            of: userProperties) { userPropertyPointer in
                            if let userPropertyPointer,
                               let userPropertyCount = self.userProperties?.count {
                                raw_publish_view.user_property_count = userPropertyCount
                                raw_publish_view.user_properties =
                                    UnsafePointer<aws_mqtt5_user_property>(userPropertyPointer)
                            }
                            return withOptionalByteCursorPointerFromStrings(
                                    responseTopic,
                                    contentType) { cResponseTopic, cContentType in
                                raw_publish_view.content_type = cContentType
                                raw_publish_view.response_topic = cResponseTopic

                                return withAWSByteCursorPointerFromOptionalData(to: self.correlationData) {  cCorrelationData in
                                    raw_publish_view.correlation_data = cCorrelationData
                                    return body(raw_publish_view)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

/// Publish result returned by Publish operation.
/// - Members
///   - puback: returned PublishPacket for qos 1 publish; nil for qos 0 packet.
public class PublishResult {
    public let puback: PubackPacket?

    public init (puback: PubackPacket? = nil) {
        self.puback = puback
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

    internal init(_ puback_view: UnsafePointer<aws_mqtt5_packet_puback_view>) {
        let pubackView = puback_view.pointee
        self.reasonCode = PubackReasonCode(rawValue: Int(pubackView.reason_code.rawValue))!
        self.reasonString = pubackView.reason_string?.pointee.toString()
        self.userProperties = convertOptionalUserProperties(
            count: pubackView.user_property_count,
            userPropertiesPointer: pubackView.user_properties)
    }
}

/// Configures a single subscription within a Subscribe operation
public class Subscription: CStruct {

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

        aws_byte_buf_clean_up(&topicFilterBuffer)
        _ = self.topicFilter.withByteCursor { topicFilterCursor in
            aws_byte_buf_init_copy_from_cursor(&topicFilterBuffer, allocator, topicFilterCursor)
        }
    }

    private var topicFilterBuffer = aws_byte_buf()

    typealias RawType = aws_mqtt5_subscription_view
    func withCStruct<Result>(_ body: (RawType) -> Result) -> Result {
        var view = aws_mqtt5_subscription_view()
        view.qos = self.qos.rawValue
        view.no_local = self.noLocal ?? false
        view.retain_as_published = self.retainAsPublished ?? false
        if let retainType = self.retainHandlingType {
            view.retain_handling_type = retainType.rawValue
        } else {
            view.retain_handling_type = aws_mqtt5_retain_handling_type(0)
        }

        view.topic_filter = aws_byte_cursor_from_buf(&topicFilterBuffer)
        return body(view)
    }

    deinit {
        aws_byte_buf_clean_up(&topicFilterBuffer)
    }

}

extension Array where Element == Subscription {
    func withCSubscriptions<Result>(_ body: (OpaquePointer) throws -> Result) rethrows -> Result {
        let array_list: UnsafeMutablePointer<aws_array_list> = allocator.allocate(capacity: 1)
        defer {
            aws_array_list_clean_up(array_list)
            allocator.release(array_list)
        }
        guard aws_array_list_init_dynamic(
            array_list,
            allocator.rawValue,
            count,
            MemoryLayout<Element.RawType>.size) == AWS_OP_SUCCESS else {
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

/// Data model of an `MQTT5 SUBSCRIBE <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901161>`_ packet.
public class SubscribePacket: CStruct {

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
                             noLocal: Bool? = nil,
                             retainAsPublished: Bool? = nil,
                             retainHandlingType: RetainHandlingType? = nil,
                             subscriptionIdentifier: UInt32? = nil,
                             userProperties: [UserProperty]? = nil) {
        self.init(subscriptions: [Subscription(topicFilter: topicFilter,
                                               qos: qos,
                                               noLocal: noLocal,
                                               retainAsPublished: retainAsPublished,
                                               retainHandlingType: retainHandlingType)],
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

    typealias RawType = aws_mqtt5_packet_subscribe_view
    func withCStruct<Result>(_ body: (RawType) -> Result) -> Result {
        var raw_subscrbe_view = aws_mqtt5_packet_subscribe_view()
        return self.subscriptions.withCSubscriptions { subscriptionPointer in
            raw_subscrbe_view.subscriptions =
                UnsafePointer<aws_mqtt5_subscription_view>(subscriptionPointer)
            raw_subscrbe_view.subscription_count = self.subscriptions.count

            return withOptionalUserPropertyArray(
                of: userProperties) { userPropertyPointer in

                    if let userPropertyPointer,
                       let userPropertyCount = userProperties?.count {
                        raw_subscrbe_view.user_property_count = userPropertyCount
                        raw_subscrbe_view.user_properties =
                            UnsafePointer<aws_mqtt5_user_property>(userPropertyPointer)
                    }

                    return withOptionalUnsafePointer(
                        to: self.subscriptionIdentifier) { identiferPointer in
                            raw_subscrbe_view.subscription_identifier = identiferPointer
                            return body(raw_subscrbe_view)
                    }
            }
        }
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

    internal init(_ suback_view: UnsafePointer<aws_mqtt5_packet_suback_view>) {
        let subackView = suback_view.pointee
        let reasonCodeBuffer = UnsafeBufferPointer(start: subackView.reason_codes, count: subackView.reason_code_count)
        self.reasonCodes = reasonCodeBuffer.compactMap { SubackReasonCode(rawValue: Int($0.rawValue)) }
        self.reasonString = subackView.reason_string?.pointee.toString()
        self.userProperties = convertOptionalUserProperties(
            count: subackView.user_property_count,
            userPropertiesPointer: subackView.user_properties)
    }
}

/// Data model of an `MQTT5 UNSUBSCRIBE <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc384800445>`_ packet.
public class UnsubscribePacket: CStruct {

    /// Array of topic filters that the client wishes to unsubscribe from.
    public let topicFilters: [String]

    /// Array of MQTT5 user properties included with the packet.
    public let userProperties: [UserProperty]?

    public init (topicFilters: [String],
                 userProperties: [UserProperty]? = nil) {
        self.topicFilters = topicFilters
        self.userProperties = userProperties
        rawTopicFilters = convertTopicFilters(self.topicFilters)
    }

    // Allow an UnsubscribePacket to be created directly using a single topic filter
    public convenience init (topicFilter: String,
                             userProperties: [UserProperty]? = nil) {
        self.init(topicFilters: [topicFilter], userProperties: userProperties)
    }

    typealias RawType = aws_mqtt5_packet_unsubscribe_view
    func withCStruct<Result>(_ body: (RawType) -> Result) -> Result {
        var raw_unsubscribe_view = aws_mqtt5_packet_unsubscribe_view()
        raw_unsubscribe_view.topic_filters = UnsafePointer(rawTopicFilters)
        raw_unsubscribe_view.topic_filter_count = topicFilters.count
        return withOptionalUserPropertyArray(of: userProperties) { userPropertyPointer in
                if let _userPropertyPointer = userPropertyPointer {
                    raw_unsubscribe_view.user_property_count = userProperties!.count
                    raw_unsubscribe_view.user_properties =
                        UnsafePointer<aws_mqtt5_user_property>(_userPropertyPointer)
            }
            return body(raw_unsubscribe_view)
        }
    }

    func convertTopicFilters(_ topicFilters: [String]) -> UnsafeMutablePointer<aws_byte_cursor>? {
        let cArray = UnsafeMutablePointer<aws_byte_cursor>.allocate(capacity: topicFilters.count)

        for (index, string) in topicFilters.enumerated() {
            let data = Data(string.utf8)
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
            data.copyBytes(to: buffer, count: data.count)

            cArray[index] = aws_byte_cursor(len: data.count, ptr: buffer)
        }

        return cArray
    }

    /// storage of topic filter Strings converted into native c aws_byte_cursor pointer
    private var rawTopicFilters: UnsafeMutablePointer<aws_byte_cursor>?

    deinit {
        /// Clean up memory of converted topic filter Strings
        if let filters = rawTopicFilters {
            for i in 0..<topicFilters.count {
                filters[i].ptr.deallocate()
            }
            filters.deallocate()
        }
    }
}

/// Data model of an `MQTT5 UNSUBACK <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc471483687>`_ packet.
public class UnsubackPacket {

    /// Array of reason codes indicating the result of unsubscribing from each individual topic filter entry in the associated UNSUBSCRIBE packet.
    public let reasonCodes: [UnsubackReasonCode]

    /// Additional diagnostic information about the result of the UNSUBSCRIBE attempt.
    public let reasonString: String?

    /// Array of MQTT5 user properties included with the packet.
    public let userProperties: [UserProperty]?

    public init (reasonCodes: [UnsubackReasonCode],
                 reasonString: String? = nil,
                 userProperties: [UserProperty]? = nil) {
        self.reasonCodes = reasonCodes
        self.reasonString = reasonString
        self.userProperties = userProperties
    }

    internal init(_ unsuback_view: UnsafePointer<aws_mqtt5_packet_unsuback_view>) {
        let unsubackView = unsuback_view.pointee
        let reasonCodeBuffer = UnsafeBufferPointer(start: unsubackView.reason_codes, count: unsubackView.reason_code_count)
        self.reasonCodes = reasonCodeBuffer.compactMap { UnsubackReasonCode(rawValue: Int($0.rawValue)) }
        self.reasonString = unsubackView.reason_string?.pointee.toString()
        self.userProperties = convertOptionalUserProperties(
            count: unsubackView.user_property_count,
            userPropertiesPointer: unsubackView.user_properties)
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

    internal init(_ disconnect_view: UnsafePointer<aws_mqtt5_packet_disconnect_view>) {
        let disconnectView = disconnect_view.pointee

        self.reasonCode = DisconnectReasonCode(rawValue: Int(disconnectView.reason_code.rawValue))!
        self.sessionExpiryInterval = (disconnectView.session_expiry_interval_seconds?.pointee).map { TimeInterval($0) }
        self.reasonString = disconnectView.reason_string?.pointee.toString()
        self.serverReference = disconnectView.reason_string?.pointee.toString()
        self.userProperties = convertOptionalUserProperties(
            count: disconnectView.user_property_count,
            userPropertiesPointer: disconnectView.user_properties)
    }

    func validateConversionToNative() throws {
        if let sessionExpiryInterval {
            if sessionExpiryInterval < 0 || sessionExpiryInterval > Double(UInt32.max) {
                throw CommonRunTimeError.crtError(CRTError(code: AWS_ERROR_INVALID_ARGUMENT.rawValue,
                                                           context: "Invalid sessionExpiryInterval value"))
            }
        }
    }

    typealias RawType = aws_mqtt5_packet_disconnect_view
    func withCStruct<Result>(_ body: (aws_mqtt5_packet_disconnect_view) -> Result) -> Result {
        var raw_disconnect_view = aws_mqtt5_packet_disconnect_view()

        raw_disconnect_view.reason_code = aws_mqtt5_disconnect_reason_code(UInt32(reasonCode.rawValue))

        let _sessionExpiryInterval = try? sessionExpiryInterval?.secondUInt32()

        return withOptionalUnsafePointer(to: _sessionExpiryInterval) { sessionExpiryIntervalPointer in

            raw_disconnect_view.session_expiry_interval_seconds = sessionExpiryIntervalPointer

            return withOptionalUserPropertyArray(
                of: userProperties) { userPropertyPointer in

                if let userPropertyPointer,
                    let userPropertyCount = userProperties?.count {
                    raw_disconnect_view.user_property_count = userPropertyCount
                    raw_disconnect_view.user_properties =
                        UnsafePointer<aws_mqtt5_user_property>(userPropertyPointer)
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

    internal init(_ connack_view: UnsafePointer<aws_mqtt5_packet_connack_view>) {
        let connackView = connack_view.pointee

        self.sessionPresent = connackView.session_present
        self.reasonCode = ConnectReasonCode(rawValue: Int(connackView.reason_code.rawValue))!
        self.sessionExpiryInterval = (connackView.session_expiry_interval?.pointee).map { TimeInterval($0) }
        self.receiveMaximum = connackView.receive_maximum?.pointee
        if let maximumQosValue = connackView.maximum_qos {
            self.maximumQos = QoS(maximumQosValue.pointee)
        } else {
            self.maximumQos = nil
        }
        self.retainAvailable = connackView.retain_available?.pointee
        self.maximumPacketSize = connackView.maximum_packet_size?.pointee
        self.assignedClientIdentifier = connackView.assigned_client_identifier?.pointee.toString()
        self.topicAliasMaximum = connackView.topic_alias_maximum?.pointee
        self.reasonString = connackView.reason_string?.pointee.toString()
        self.wildcardSubscriptionsAvailable = connackView.wildcard_subscriptions_available?.pointee
        self.subscriptionIdentifiersAvailable = connackView.subscription_identifiers_available?.pointee
        self.sharedSubscriptionAvailable = connackView.shared_subscriptions_available?.pointee
        self.serverKeepAlive = (connackView.server_keep_alive?.pointee).map { TimeInterval($0) }
        self.responseInformation = connackView.response_information?.pointee.toString()
        self.serverReference = connackView.server_reference?.pointee.toString()
        self.userProperties = convertOptionalUserProperties(
            count: connackView.user_property_count,
            userPropertiesPointer: connackView.user_properties)
    }
}
