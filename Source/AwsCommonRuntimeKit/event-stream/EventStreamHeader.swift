//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCEventStreams
import AwsCCommon
import Foundation

public enum EventStreamHeaderType: Equatable {
    case bool(value: Bool)
    case byte(value: Int8)
    case int16(value: Int16)
    case int32(value: Int32)
    case int64(value: Int64)
    case byteBuf(value: Data)
    case string(value: String)
    /// Timestamp is in milliseconds
    case timestamp(value: Int64)
    case uuid(value: UUID)
}

extension EventStreamHeaderType {
    static func parseRaw(rawValue: UnsafeMutablePointer<aws_event_stream_header_value_pair>) -> EventStreamHeaderType {
        let value: EventStreamHeaderType
        switch rawValue.pointee.header_value_type {
        case AWS_EVENT_STREAM_HEADER_BOOL_TRUE:
            value = .bool(
                    value: aws_event_stream_header_value_as_bool(rawValue) != 0)
        case AWS_EVENT_STREAM_HEADER_BOOL_FALSE:
            value = .bool(
                    value: aws_event_stream_header_value_as_bool(rawValue) != 0)
        case AWS_EVENT_STREAM_HEADER_BYTE:
            value = .byte(value: aws_event_stream_header_value_as_byte(rawValue))
        case AWS_EVENT_STREAM_HEADER_INT16:
            value = .int16(
                    value: aws_event_stream_header_value_as_int16(rawValue))
        case AWS_EVENT_STREAM_HEADER_INT32:
            value = .int32(
                    value: aws_event_stream_header_value_as_int32(rawValue))
        case AWS_EVENT_STREAM_HEADER_INT64:
            value = .int64(
                    value: aws_event_stream_header_value_as_int64(rawValue))
        case AWS_EVENT_STREAM_HEADER_BYTE_BUF:
            value = .byteBuf(
                    value: aws_event_stream_header_value_as_bytebuf(rawValue).toData())
        case AWS_EVENT_STREAM_HEADER_STRING:
            value = .string(
                    value: aws_event_stream_header_value_as_string(rawValue).toString())
        case AWS_EVENT_STREAM_HEADER_TIMESTAMP:
            value = .timestamp(
                    value: aws_event_stream_header_value_as_timestamp(rawValue))
        case AWS_EVENT_STREAM_HEADER_UUID:
            let uuid = UUID(uuid: rawValue.pointee.header_value.static_val)
            value = .uuid(value: uuid)
        default:
            fatalError("Unable to convert header")
        }
        return value
    }
}

public struct EventStreamHeader {
    public let name: String
    public let value: EventStreamHeaderType

    public init(name: String, value: EventStreamHeaderType) {
        self.name = name
        self.value = value
    }
}

extension EventStreamHeader: Equatable {
    public static func == (lhs: EventStreamHeader, rhs: EventStreamHeader) -> Bool {
            lhs.name == rhs.name &&
            lhs.value == rhs.value
    }
}