//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCCommon
import Foundation

/// CBOR Types. These types don't map one-to-one to the CBOR RFC.
public enum CBORType: Equatable {
    /// UINT64 type for positive numbers.
    case uint64(_ value: UInt64)
    /// INT64 type for negative numbers. If the number is positive, it will be encoded as UINT64 type.
    case int(_ value: Int64)
    /// Double type. It might be encoded as an integer if possible without loss of precision. Half-precision floats are not supported.
    case double(_ value: Double)
    /// Bytes type for binary data
    case bytes(_ value: Data)
    /// Text type for utf-8 encoded strings
    case text(_ value: String)
    /// Array type
    case array(_ value: [CBORType])
    /// Map type
    case map(_ value: [String: CBORType])
    /// Date type. It will be encoded as epoch-based date/time.
    case date(_ value: Date)
    /// Bool type
    case bool(_ value: Bool)
    /// Null type
    case null
    /// Undefined type
    case undefined
    /// Break type for indefinite-length arrays, maps, bytes, and text. For encoding, you should start the encoding
    /// with `indef_*_start` and then end the encoding with this `indef_break` type. During decoding, you will get 
    /// the `indef_*_start` type first, followed by N elements, and the break type at the end.
    case indef_break
    /// Indefinite Array Type
    case indef_array_start
    /// Indefinite Map Type
    case indef_map_start
    /// Indefinite Bytes Type
    case indef_bytes_start
    /// Indefinite Text Type
    case indef_text_start
}

/// Encoder for the CBOR Types.
public class CBOREncoder {
    var rawValue: OpaquePointer

    public init() throws {
        let rawValue = aws_cbor_encoder_new(allocator.rawValue)
        guard let rawValue else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        self.rawValue = rawValue
    }

    /// Encode a single type
    /// - Parameters:
    ///   - value: value to encode 
    /// - Throws: CommonRuntimeError.crtError
    public func encode(_ value: CBORType) {
        switch value {
        case .uint64(let value): aws_cbor_encoder_write_uint(self.rawValue, value)
        case .int(let value):
            do {
                if value >= 0 {
                    aws_cbor_encoder_write_uint(self.rawValue, UInt64(value))
                } else {
                    aws_cbor_encoder_write_negint(self.rawValue, UInt64(-1 - value))
                }
            }
        case .double(let value): aws_cbor_encoder_write_float(self.rawValue, value)
        case .array(let values):
            do {
                aws_cbor_encoder_write_array_start(self.rawValue, values.count)
                for value in values {
                    encode(value)
                }
            }
        case .bool(let value): aws_cbor_encoder_write_bool(self.rawValue, value)
        case .bytes(let value):
            do {
                value.withAWSByteCursorPointer { cursor in
                    aws_cbor_encoder_write_bytes(self.rawValue, cursor.pointee)
                }
            }
        case .map(let values):
            do {
                aws_cbor_encoder_write_map_start(self.rawValue, values.count)
                for (key, value) in values {
                    encode(.text(key))
                    encode(value)
                }
            }
        case .null: aws_cbor_encoder_write_null(self.rawValue)
        case .text(let value):
            do {
                value.withByteCursor { cursor in
                    aws_cbor_encoder_write_text(self.rawValue, cursor)
                }
            }
        case .date(let value):
            do {
                aws_cbor_encoder_write_tag(self.rawValue, UInt64(AWS_CBOR_TAG_EPOCH_TIME))
                aws_cbor_encoder_write_float(self.rawValue, value.timeIntervalSince1970)
            }
        case .undefined: aws_cbor_encoder_write_undefined(self.rawValue)
        case .indef_break: aws_cbor_encoder_write_break(self.rawValue)
        case .indef_array_start: aws_cbor_encoder_write_indef_array_start(self.rawValue)
        case .indef_map_start: aws_cbor_encoder_write_indef_map_start(self.rawValue)
        case .indef_bytes_start: aws_cbor_encoder_write_indef_bytes_start(self.rawValue)
        case .indef_text_start: aws_cbor_encoder_write_indef_text_start(self.rawValue)
        }
    }

    /// Get all the values encoded so far as an array of raw bytes.
    /// This won't reset the encoder, and you will get all the bytes encoded so far from the beginning.
    public func getEncoded() -> [UInt8] {
        aws_cbor_encoder_get_encoded_data(self.rawValue).toArray()
    }

    deinit {
        aws_cbor_encoder_destroy(rawValue)
    }
}

/// Decoder for the CBOR encoding.
public class CBORDecoder {
    var rawValue: OpaquePointer
    // Keep a reference to data to make it outlive the decoder
    var data: [UInt8]

    public init(data: [UInt8]) throws {
        self.data = data
        let count = self.data.count
        let rawValue = self.data.withUnsafeBytes {
            let cursor = aws_byte_cursor_from_array($0.baseAddress, count)
            return aws_cbor_decoder_new(allocator.rawValue, cursor)
        }
        guard let rawValue else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        self.rawValue = rawValue
    }

    // swiftlint:disable function_body_length 
    /// Decodes and returns the next value. If there is no value, this function will throw an error. 
    /// You must call `hasNext()` before calling this function.
    public func popNext() throws -> CBORType {
        var cbor_type: aws_cbor_type = AWS_CBOR_TYPE_UNKNOWN
        guard aws_cbor_decoder_peek_type(self.rawValue, &cbor_type) == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        switch cbor_type {
        case AWS_CBOR_TYPE_UINT:
            do {
                var out_value: UInt64 = 0
                guard
                    aws_cbor_decoder_pop_next_unsigned_int_val(self.rawValue, &out_value)
                        == AWS_OP_SUCCESS
                else {
                    throw CommonRunTimeError.crtError(.makeFromLastError())
                }
                return .uint64(out_value)
            }

        case AWS_CBOR_TYPE_NEGINT:
            do {
                var out_value: UInt64 = 0
                guard
                    aws_cbor_decoder_pop_next_negative_int_val(self.rawValue, &out_value)
                        == AWS_OP_SUCCESS
                else {
                    throw CommonRunTimeError.crtError(.makeFromLastError())
                }
                return .int(-(Int64(out_value + 1)))
            }
        case AWS_CBOR_TYPE_FLOAT:
            do {
                var out_value: Double = 0
                guard
                    aws_cbor_decoder_pop_next_float_val(self.rawValue, &out_value)
                        == AWS_OP_SUCCESS
                else {
                    throw CommonRunTimeError.crtError(.makeFromLastError())
                }
                return .double(out_value)
            }
        case AWS_CBOR_TYPE_BYTES:
            do {
                var out_value: aws_byte_cursor = aws_byte_cursor()
                guard
                    aws_cbor_decoder_pop_next_bytes_val(self.rawValue, &out_value)
                        == AWS_OP_SUCCESS
                else {
                    throw CommonRunTimeError.crtError(.makeFromLastError())
                }
                return .bytes(out_value.toData())
            }
        case AWS_CBOR_TYPE_TEXT:
            do {
                var out_value: aws_byte_cursor = aws_byte_cursor()
                guard
                    aws_cbor_decoder_pop_next_text_val(self.rawValue, &out_value)
                        == AWS_OP_SUCCESS
                else {
                    throw CommonRunTimeError.crtError(.makeFromLastError())
                }
                return .text(out_value.toString())
            }
        case AWS_CBOR_TYPE_BOOL:
            do {
                var out_value: Bool = false
                guard
                    aws_cbor_decoder_pop_next_boolean_val(self.rawValue, &out_value)
                        == AWS_OP_SUCCESS
                else {
                    throw CommonRunTimeError.crtError(.makeFromLastError())
                }
                return .bool(out_value)
            }
        case AWS_CBOR_TYPE_NULL:
            do {
                guard
                    aws_cbor_decoder_consume_next_single_element(self.rawValue)
                        == AWS_OP_SUCCESS
                else {
                    throw CommonRunTimeError.crtError(.makeFromLastError())
                }
                return .null
            }
        case AWS_CBOR_TYPE_TAG:
            var out_value: UInt64 = 0
            guard
                aws_cbor_decoder_pop_next_tag_val(self.rawValue, &out_value)
                    == AWS_OP_SUCCESS
            else {
                throw CommonRunTimeError.crtError(.makeFromLastError())
            }
            guard
                out_value == 1
            else {
                throw CommonRunTimeError.crtError(CRTError(code: AWS_ERROR_CBOR_UNEXPECTED_TYPE.rawValue))
            }
            let timestamp = try popNext()

            if case .double(let value) = timestamp {
                return .date(Date.init(timeIntervalSince1970: value))
            } else if case .uint64(let value) = timestamp {
                return .date(Date.init(timeIntervalSince1970: Double(value)))
            } else if case .int(let value) = timestamp {
                return .date(Date.init(timeIntervalSince1970: Double(value)))
            } else {
                throw CommonRunTimeError.crtError(CRTError(code: AWS_ERROR_CBOR_UNEXPECTED_TYPE.rawValue))
            }
        case AWS_CBOR_TYPE_ARRAY_START:
            var out_value: UInt64 = 0
            guard
                aws_cbor_decoder_pop_next_array_start(self.rawValue, &out_value)
                    == AWS_OP_SUCCESS
            else {
                throw CommonRunTimeError.crtError(.makeFromLastError())
            }
            var array: [CBORType] = []
            for _ in 0..<out_value {
                array.append(try popNext())
            }
            return .array(array)
        case AWS_CBOR_TYPE_MAP_START:
            var out_value: UInt64 = 0
            guard
                aws_cbor_decoder_pop_next_map_start(self.rawValue, &out_value)
                    == AWS_OP_SUCCESS
            else {
                throw CommonRunTimeError.crtError(.makeFromLastError())
            }
            var map: [String: CBORType] = [:]
            for _ in 0..<out_value {
                let key = try popNext()
                if case .text(let key) = key {
                    map[key] = try popNext()
                } else {
                    throw CommonRunTimeError.crtError(CRTError(code: AWS_ERROR_CBOR_UNEXPECTED_TYPE.rawValue))
                }
            }
            return .map(map)
        case AWS_CBOR_TYPE_UNDEFINED:
            do {
                guard
                    aws_cbor_decoder_consume_next_single_element(self.rawValue)
                        == AWS_OP_SUCCESS
                else {
                    throw CommonRunTimeError.crtError(.makeFromLastError())
                }
                return .undefined
            }
        case AWS_CBOR_TYPE_BREAK:
            do {
                guard
                    aws_cbor_decoder_consume_next_single_element(self.rawValue)
                        == AWS_OP_SUCCESS
                else {
                    throw CommonRunTimeError.crtError(.makeFromLastError())
                }
                return .indef_break
            }
        case AWS_CBOR_TYPE_INDEF_ARRAY_START:
            do {
                guard
                    aws_cbor_decoder_consume_next_single_element(self.rawValue)
                        == AWS_OP_SUCCESS
                else {
                    throw CommonRunTimeError.crtError(.makeFromLastError())
                }
                return .indef_array_start
            }
        case AWS_CBOR_TYPE_INDEF_MAP_START:
            do {
                guard
                    aws_cbor_decoder_consume_next_single_element(self.rawValue)
                        == AWS_OP_SUCCESS
                else {
                    throw CommonRunTimeError.crtError(.makeFromLastError())
                }
                return .indef_map_start
            }

        case AWS_CBOR_TYPE_INDEF_BYTES_START:
            do {
                guard
                    aws_cbor_decoder_consume_next_single_element(self.rawValue)
                        == AWS_OP_SUCCESS
                else {
                    throw CommonRunTimeError.crtError(.makeFromLastError())
                }
                return .indef_bytes_start
            }
        case AWS_CBOR_TYPE_INDEF_TEXT_START:
            do {
                guard
                    aws_cbor_decoder_consume_next_single_element(self.rawValue)
                        == AWS_OP_SUCCESS
                else {
                    throw CommonRunTimeError.crtError(.makeFromLastError())
                }
                return .indef_text_start
            }
        default:
            throw CommonRunTimeError.crtError(CRTError(code: AWS_ERROR_CBOR_UNEXPECTED_TYPE.rawValue))
        }
    }

    /// Returns true if there is any data left to decode.
    public func hasNext() -> Bool {
        aws_cbor_decoder_get_remaining_length(self.rawValue) != 0
    }

    deinit {
        aws_cbor_decoder_destroy(rawValue)
    }
}
