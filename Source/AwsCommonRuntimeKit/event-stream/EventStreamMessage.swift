//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCEventStreams
import Foundation

public class EventStreamMessage {
    var rawValue: aws_event_stream_message
    var rawHeaders: aws_array_list

    // TODO: use an immutable buffer over data and avoid a copy.
    public init(headers: [EventStreamHeader], payload: Data, allocator: Allocator = defaultAllocator) throws {
        self.rawValue = aws_event_stream_message()
        self.rawHeaders = aws_array_list()

        guard aws_event_stream_headers_list_init(&rawHeaders, allocator.rawValue) == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }

        try headers.forEach { try addHeader(header: $0) }

        guard (payload.withAWSByteBuffPointer { byteBuff in
            return aws_event_stream_message_init(&rawValue, allocator.rawValue, &rawHeaders, byteBuff)
        }) == AWS_OP_SUCCESS
        else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
    }

    init(rawValue: aws_event_stream_message) {
        self.rawValue = rawValue
        self.rawHeaders = aws_array_list()
    }

    deinit {
        aws_event_stream_message_clean_up(&rawValue)
    }
}

// TODO: aws_event_stream_streaming_decoder_init bind maybe

extension EventStreamMessage: CustomDebugStringConvertible {
    public var debugDescription: String {
        aws_event_stream_message_to_debug_str(stdout, &rawValue)
        return "printed event stream message"
    }

    public func addHeader(header: EventStreamHeader) throws {
        let addCHeader: () -> Int32 = {
            return header.name.withCString { headerName in

                switch header.value {
                case .bool(let value):
                    return aws_event_stream_add_bool_header(
                        &self.rawHeaders,
                        headerName,
                        UInt8(header.name.count),
                        Int8(value.uintValue))
                case .byte(let value):
                    return aws_event_stream_add_byte_header(
                        &self.rawHeaders,
                        headerName,
                        UInt8(header.name.count),
                        value)
                case .int16(let value):
                    return aws_event_stream_add_int16_header(
                        &self.rawHeaders,
                        headerName,
                        UInt8(header.name.count),
                        value)
                case .int32(let value):
                    return aws_event_stream_add_int32_header(
                        &self.rawHeaders,
                        headerName,
                        UInt8(header.name.count),
                        value)
                case .int64(let value):
                    return aws_event_stream_add_int64_header(
                        &self.rawHeaders,
                        headerName,
                        UInt8(header.name.count),
                        value)
                case .byteBuf(var value):
                    return value.withUnsafeMutableBufferPointer {
                        aws_event_stream_add_bytebuf_header(
                            &self.rawHeaders,
                            headerName,
                            UInt8(header.name.count),
                            $0.baseAddress!,
                            UInt16($0.count),
                            1) // TODO: confirm true,
                               // maybe we can avoid allocation here and just copy all headers once initialized
                    }
                case .string(let value):
                    return value.withCString {
                        aws_event_stream_add_string_header(
                            &self.rawHeaders,
                            headerName,
                            UInt8(header.name.count),
                            $0,
                            UInt16(value.count),
                            1) // TODO: confirm true
                    }
                case .timestamp(let value):
                    return aws_event_stream_add_timestamp_header(
                        &self.rawHeaders,
                        headerName,
                        UInt8(header.name.count),
                        Int64(value.millisecond))
                case .uuid(let value):
                    var uuidString = value.uuidString
                    return uuidString.withUTF8 {
                        aws_event_stream_add_uuid_header(
                            &self.rawHeaders,
                            headerName,
                            UInt8(header.name.count),
                            $0.baseAddress!)
                    }
                }
            }
        }
        guard addCHeader() == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
    }
}
