//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCEventStreams
import AwsCCommon
import Foundation

public enum EventStreamHeaderType {
    case bool(value: Bool)
    case byte(value: Int8)
    case int16(value: Int16)
    case int32(value: Int32)
    case int64(value: Int64)
    case byteBuf(value: [UInt8]) // TODO: confirm type
    case string(value: String)
    case timestamp(value: TimeInterval)
    case uuid(value: UUID)
}

extension EventStreamHeaderType {
    static func parseRaw(rawValue: aws_event_stream_header_value_pair) -> EventStreamHeaderType {
        var rawValue = rawValue
        let value: EventStreamHeaderType
        switch rawValue.header_value_type {
        case AWS_EVENT_STREAM_HEADER_BOOL_TRUE:
            value = .bool(
                    value: aws_event_stream_header_value_as_bool(&rawValue) != 0)
        case AWS_EVENT_STREAM_HEADER_BOOL_FALSE:
            value = .bool(
                    value: aws_event_stream_header_value_as_bool(&rawValue) != 0)
        case AWS_EVENT_STREAM_HEADER_BYTE:
            value = .byte(value: aws_event_stream_header_value_as_byte(&rawValue))
        case AWS_EVENT_STREAM_HEADER_INT16:
            value = .int16(
                    value: aws_event_stream_header_value_as_int16(&rawValue))
        case AWS_EVENT_STREAM_HEADER_INT32:
            value = .int32(
                    value: aws_event_stream_header_value_as_int32(&rawValue))
        case AWS_EVENT_STREAM_HEADER_INT64:
            value = .int64(
                    value: aws_event_stream_header_value_as_int64(&rawValue))
        case AWS_EVENT_STREAM_HEADER_BYTE_BUF: //TODO: fix
            value = .bool(
                    value: aws_event_stream_header_value_as_bool(&rawValue) != 0)
        case AWS_EVENT_STREAM_HEADER_STRING:
            value = .string(
                    value: aws_event_stream_header_value_as_string(&rawValue).toString())
        case AWS_EVENT_STREAM_HEADER_TIMESTAMP:
            value = .timestamp(
                    value: TimeInterval(aws_event_stream_header_value_as_timestamp(&rawValue)/1000))
        case AWS_EVENT_STREAM_HEADER_UUID:
            value = .uuid(
                    value: UUID(
                            uuidString: aws_event_stream_header_value_as_uuid(&rawValue).toString())!)
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
