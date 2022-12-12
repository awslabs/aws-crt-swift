//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCEventStreams
import AwsCCommon
import Foundation

public class EventStreamMessageEncoder {
    var rawValue: aws_event_stream_message
    var rawHeaders: aws_array_list

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

    /// Zero allocation, Zero copy. The message will simply wrap the buffer.
    /// The message functions are only useful as long as buffer is referencable memory.
    /// - Parameters:
    ///   - buffer: The buffer to initialize the event stream message.
    ///             This should stay valid for the duration of the EventStreamMessage
    ///   - allocator:
    public init(fromBuffer buffer:  UnsafeBufferPointer<UInt8>, allocator: Allocator = defaultAllocator) throws {
        self.rawHeaders = aws_array_list()
        self.rawValue = aws_event_stream_message()
        var awsBuffer = aws_byte_buf_from_array(buffer.baseAddress, buffer.count)
        guard aws_event_stream_message_from_buffer(
                &rawValue,
                allocator.rawValue,
                &awsBuffer) == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
    }

    /// Allocates memory and copies buffer. Otherwise the same as aws_aws_event_stream_message_from_buffer.
    /// This is slower, but possibly safer.
    /// - Parameters:
    ///   - buffer: The buffer to initialize the event stream message.
    ///   - allocator:
    public init(fromBufferSafe buffer:  UnsafeBufferPointer<UInt8>, allocator: Allocator = defaultAllocator) throws {
        self.rawHeaders = aws_array_list()
        self.rawValue = aws_event_stream_message()
        var awsBuffer = aws_byte_buf_from_array(buffer.baseAddress, buffer.count)
        guard aws_event_stream_message_from_buffer_copy(
                &rawValue,
                allocator.rawValue,
                &awsBuffer) == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
    }

    /// - Returns: The total length of the message (including the length field).
    public func getTotalLength() -> UInt32 {
        aws_event_stream_message_total_length(&rawValue)
    }

    /// - Returns: The length of the headers portion of the message.
    public func getHeadersLength() -> UInt32 {
        aws_event_stream_message_headers_len(&rawValue)
    }

    /// - Returns: The length of the message payload.
    public func getPayloadLength() -> UInt32 {
        aws_event_stream_message_payload_len(&rawValue)
    }

    /// - Returns: The checksum of the entire message (crc32)
    public func getCRC() -> UInt32 {
        aws_event_stream_message_message_crc(&rawValue)
    }

    /// - Returns: The prelude crc (crc32)
    public func getPreludeCRC() -> UInt32 {
        aws_event_stream_message_prelude_crc(&rawValue)
    }

    //TODO: aws_event_stream_message_payload,
    // aws_event_stream_compute_headers_required_buffer_len
    // aws_event_stream_read_headers_from_buffer

    /// Get the binary format of this message (i.e. for sending across the wire manually)
    /// - Returns:  UnsafeBufferPointer<UInt8> wrapping the underlying message data.
    ///             This buffer is only valid as long as the message itself is valid.
    public func getEncodedAsBuffer() -> UnsafeBufferPointer<UInt8> {
        UnsafeBufferPointer(
                start: aws_event_stream_message_buffer(&rawValue),
                count: rawValue.message_buffer.len)
    }

    /// Get the binary format of headers in this message
    /// - Returns:  UnsafeBufferPointer<UInt8> wrapping the underlying message headers.
    ///             This buffer is only valid as long as the message itself is valid.
    public func getEncodedHeadersAsBuffer() throws -> UnsafeBufferPointer<UInt8> {
        var awsBuffer = aws_byte_buf()
        guard aws_event_stream_write_headers_to_buffer_safe(
                &rawHeaders,
                &awsBuffer) == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }

        return UnsafeBufferPointer(
                start: awsBuffer.buffer,
                count: awsBuffer.len)
    }


    deinit {
        aws_event_stream_headers_list_cleanup(&rawHeaders)
        aws_event_stream_message_clean_up(&rawValue)
    }
}

extension EventStreamMessageEncoder: CustomDebugStringConvertible {
    // TODO: fix
    public var debugDescription: String {
        aws_event_stream_message_to_debug_str(stdout, &rawValue)
        return "printed event stream message"
    }

    func addHeader(header: EventStreamHeader) throws {
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
