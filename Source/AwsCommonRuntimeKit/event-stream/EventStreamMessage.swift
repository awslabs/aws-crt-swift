//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCEventStream
import Foundation

public struct EventStreamMessage {
    var headers: [EventStreamHeader] = [EventStreamHeader]()
    var payload: Data = Data()
    var allocator: Allocator = defaultAllocator

    public init(headers: [EventStreamHeader] = [EventStreamHeader](),
                payload: Data = Data(),
                allocator: Allocator = defaultAllocator) {
        self.headers = headers
        self.payload = payload
        self.allocator = allocator
    }

    /// Get the binary format of this message (i.e. for sending across the wire manually)
    /// - Returns:  binary Data.
    public func getEncoded() throws -> Data {
        var rawValue = aws_event_stream_message()
        var rawHeaders = aws_array_list()
        defer {
            aws_event_stream_headers_list_cleanup(&rawHeaders)
            aws_event_stream_message_clean_up(&rawValue)
        }

        guard aws_event_stream_headers_list_init(&rawHeaders, allocator.rawValue) == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        try headers.forEach {
            try addHeader(header: $0, rawHeaders: &rawHeaders)
        }

        guard payload.withAWSByteBufPointer({ byteBuff in
            // TODO (optimization): we could avoid the extra copies of headers and data
            // if there were an API in C that let us encode everything directly into a pre-allocated buffer
            aws_event_stream_message_init(&rawValue, allocator.rawValue, &rawHeaders, byteBuff)
        }) == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }

        return Data(
            bytes: aws_event_stream_message_buffer(&rawValue),
            count: Int(aws_event_stream_message_total_length(&rawValue)))
    }
}

extension EventStreamMessage {
    func addHeader(header: EventStreamHeader, rawHeaders: UnsafeMutablePointer<aws_array_list>) throws {
        if header.name.count > EventStreamHeader.maxNameLength {
            throw CommonRunTimeError.crtError(
                .init(
                    code: AWS_ERROR_EVENT_STREAM_MESSAGE_INVALID_HEADERS_LEN.rawValue))
        }
        let addCHeader: () throws -> Int32 = {
            return try header.name.withCString { headerName in
                switch header.value {
                case .bool(let value):
                    return aws_event_stream_add_bool_header(
                        rawHeaders,
                        headerName,
                        UInt8(header.name.count),
                        Int8(value.uintValue))
                case .byte(let value):
                    return aws_event_stream_add_byte_header(
                        rawHeaders,
                        headerName,
                        UInt8(header.name.count),
                        value)
                case .int16(let value):
                    return aws_event_stream_add_int16_header(
                        rawHeaders,
                        headerName,
                        UInt8(header.name.count),
                        value)
                case .int32(let value):
                    return aws_event_stream_add_int32_header(
                        rawHeaders,
                        headerName,
                        UInt8(header.name.count),
                        value)
                case .int64(let value):
                    return aws_event_stream_add_int64_header(
                        rawHeaders,
                        headerName,
                        UInt8(header.name.count),
                        value)
                case .byteBuf(var value):
                    if value.count > EventStreamHeader.maxValueLength {
                        throw CommonRunTimeError.crtError(
                            .init(
                                code: AWS_ERROR_EVENT_STREAM_MESSAGE_INVALID_HEADERS_LEN.rawValue))
                    }
                    return value.withUnsafeMutableBytes {
                        let bytes = $0.bindMemory(to: UInt8.self).baseAddress!
                        return aws_event_stream_add_bytebuf_header(
                            rawHeaders,
                            headerName,
                            UInt8(header.name.count),
                            bytes,
                            UInt16($0.count),
                            1)
                    }
                case .string(let value):
                    if value.count > EventStreamHeader.maxValueLength {
                        throw CommonRunTimeError.crtError(
                            .init(
                                code: AWS_ERROR_EVENT_STREAM_MESSAGE_INVALID_HEADERS_LEN.rawValue))
                    }
                    return value.withCString {
                        aws_event_stream_add_string_header(
                            rawHeaders,
                            headerName,
                            UInt8(header.name.count),
                            $0,
                            UInt16(value.count),
                            1)
                    }
                case .timestamp(let value):
                    return aws_event_stream_add_timestamp_header(
                        rawHeaders,
                        headerName,
                        UInt8(header.name.count),
                        Int64(value.millisecondsSince1970))
                case .uuid(let value):
                    return withUnsafeBytes(of: value) {
                        let address = $0.baseAddress?.assumingMemoryBound(to: UInt8.self)
                        return aws_event_stream_add_uuid_header(
                            rawHeaders,
                            headerName,
                            UInt8(header.name.count),
                            address)
                    }
                }
            }
        }

        guard try addCHeader() == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
    }
}
