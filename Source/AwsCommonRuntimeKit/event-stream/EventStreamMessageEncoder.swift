//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCEventStreams
import AwsCCommon
import Foundation

public class EventStreamMessageEncoder {
    var rawValue: aws_event_stream_message

    ///  Initializes message with a list of headers, and the payload. CRCs will be computed for you.
    /// - Parameters:
    ///   - headers: (Optional) Headers to include.
    ///   - payload: (Optional) payload of message
    ///   - allocator: (Optional) allocator to override.
    /// - Throws: CommonRunTimeError.crtException
    public init(headers: [EventStreamHeader] = [EventStreamHeader](),
                payload: Data? = nil,
                allocator: Allocator = defaultAllocator) throws {
        rawValue = aws_event_stream_message()
        var rawHeaders = aws_array_list()
        defer {
            aws_event_stream_headers_list_cleanup(&rawHeaders)
        }

        guard aws_event_stream_headers_list_init(&rawHeaders, allocator.rawValue) == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }

        try headers.forEach {
            try addHeader(header: $0, rawHeaders: &rawHeaders)
        }

        guard withOptionalAWSByteBufPointer(to: payload, { byteBuff in
            aws_event_stream_message_init(&rawValue, allocator.rawValue, &rawHeaders, byteBuff)
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
    ///   - allocator: (Optional) allocator to override.
    /// - Throws: CommonRunTimeError.crtException
    public init(fromBuffer buffer: UnsafeBufferPointer<UInt8>, allocator: Allocator = defaultAllocator) throws {
        self.rawValue = aws_event_stream_message()
        var awsBuffer = aws_byte_buf_from_array(buffer.baseAddress, buffer.count)
        guard aws_event_stream_message_from_buffer(
                &rawValue,
                allocator.rawValue,
                &awsBuffer) == AWS_OP_SUCCESS
        else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
    }

    /// Allocates memory and copies buffer. Otherwise the same as fromBuffer.
    /// This is slower, but possibly safer.
    /// - Parameters:
    ///   - data: The raw data to initialize the event stream message.
    ///   - allocator: (Optional) allocator to override.
    /// - Throws: CommonRunTimeError.crtException
    public init(fromBufferSafe data: Data, allocator: Allocator = defaultAllocator) throws {
        self.rawValue = aws_event_stream_message()
        guard data.withAWSByteBufPointer({ awsBuffer in
            aws_event_stream_message_from_buffer_copy(
                &rawValue,
                allocator.rawValue,
                awsBuffer)
        }) == AWS_OP_SUCCESS
        else {
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

    /// Get the binary format of this message (i.e. for sending across the wire manually)
    /// - Returns:  UnsafeBufferPointer<UInt8> wrapping the underlying message data.
    ///             This buffer is only valid as long as the message itself is valid.
    public func getEncoded() -> Data {
        Data(
            bytes: aws_event_stream_message_buffer(&rawValue),
            count: rawValue.message_buffer.len)
    }

    deinit {
        aws_event_stream_message_clean_up(&rawValue)
    }
}

extension EventStreamMessageEncoder {
    func addHeader(header: EventStreamHeader, rawHeaders: UnsafeMutablePointer<aws_array_list>) throws {
        let addCHeader: () -> Int32 = {
            return header.name.withCString { headerName in
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
                        value)
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

        guard addCHeader() == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
    }
}
