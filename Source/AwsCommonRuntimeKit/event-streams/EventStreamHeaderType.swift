//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCEventStreams
import CoreFoundation
import CoreGraphics

public enum EventStreamHeaderType {

    case boolTrue
    case boolFalse
    case byte
    case int16
    case int32
    case int64
    case byteBuf
    case string
    case timestamp
    case uuid
}

extension EventStreamHeaderType: RawRepresentable, CaseIterable {

    public init(rawValue: aws_event_stream_header_value_type) {
        let value = Self.allCases.first(where: {$0.rawValue == rawValue})
        self = value ?? .boolTrue
    }
    public var rawValue: aws_event_stream_header_value_type {
        switch self {
        case .boolTrue: return AWS_EVENT_STREAM_HEADER_BOOL_TRUE
        case .boolFalse: return AWS_EVENT_STREAM_HEADER_BOOL_FALSE
        case .byte: return AWS_EVENT_STREAM_HEADER_BYTE
        case .int16: return AWS_EVENT_STREAM_HEADER_INT16
        case .int32: return AWS_EVENT_STREAM_HEADER_INT32
        case .int64: return AWS_EVENT_STREAM_HEADER_INT64
        case .byteBuf: return AWS_EVENT_STREAM_HEADER_BYTE_BUF
        case .string: return AWS_EVENT_STREAM_HEADER_STRING
        case .timestamp: return AWS_EVENT_STREAM_HEADER_TIMESTAMP
        case .uuid: return AWS_EVENT_STREAM_HEADER_UUID
        }
    }

}
