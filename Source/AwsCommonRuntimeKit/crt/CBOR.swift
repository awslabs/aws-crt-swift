//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCCommon
import Foundation

/// CBOR Types. These types don't map one-to-one to the CBOR RFC.
/// Numbers will be encoded using the "smallest possible" encoding.
/// Warning: This enum is non-exhaustive and subject to change in the future.
public enum CBORType: Equatable {
    /// UINT64 type for positive numbers.
    case uint(_ value: UInt64)
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
    /// Date type. It will be encoded as epoch-based time.
    /// There might be some precision loss if this is encoded as an integer and 
    /// later converted to a double in some cases.
    case date(_ value: Date)
    /// Bool type
    case bool(_ value: Bool)
    /// Null type
    case null
    /// Undefined type
    case undefined
    /// Tag type. Refer to RFC8949, section 3.4. For tag 1 (epoch-based time), 
    /// you should use the `date` type, which is a helper for this. 
    /// Values with tag 1 will be decoded as the `date` type.
    case tag(_ value: UInt64)
    /// Break type for indefinite-length arrays, maps, bytes, and text. For encoding, you should start the encoding
    /// with `indef_*_start` and then end the encoding with this `indef_break` type. During decoding, you will get 
    /// the `indef_*_start` type first, followed by N elements, and the break type at the end.
    case indef_break
    /// Indefinite Bytes Type
    case indef_bytes_start
    /// Indefinite Text Type
    case indef_text_start
    /// Indefinite Array Type
    case indef_array_start
    /// Indefinite Map Type
    case indef_map_start
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
    /// - value: value to encode
    /// - Throws: CommonRuntimeError.crtError
    public func encode(_ value: CBORType) {
        switch value {
        case .uint(let value):
            aws_cbor_encoder_write_uint(self.rawValue, value)
        case .int(let value):
            if value >= 0 {
                aws_cbor_encoder_write_uint(self.rawValue, UInt64(value))
            } else {
                aws_cbor_encoder_write_negint(self.rawValue, UInt64(-1 - value))
            }
        case .double(let value):
            aws_cbor_encoder_write_float(self.rawValue, value)
        case .bool(let value):
            aws_cbor_encoder_write_bool(self.rawValue, value)
        case .bytes(let data):
            data.withAWSByteCursorPointer { cursor in
                aws_cbor_encoder_write_bytes(self.rawValue, cursor.pointee)
            }
        case .text(let string):
            string.withByteCursor { cursor in
                aws_cbor_encoder_write_text(self.rawValue, cursor)
            }
        case .null:
            aws_cbor_encoder_write_null(self.rawValue)
        case .undefined:
            aws_cbor_encoder_write_undefined(self.rawValue)
        case .date(let date):
            aws_cbor_encoder_write_tag(self.rawValue, UInt64(AWS_CBOR_TAG_EPOCH_TIME))
            aws_cbor_encoder_write_float(self.rawValue, date.timeIntervalSince1970)
        case .tag(let tag):
            aws_cbor_encoder_write_tag(self.rawValue, tag)

        case .array(let values):
            do {
                aws_cbor_encoder_write_array_start(self.rawValue, values.count)
                for value in values {
                    encode(value)
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

// swiftlint:disable type_body_length
/// Decoder for the CBOR encoding.
public class CBORDecoder {
    var rawValue: OpaquePointer
    // Keep a reference to data to make it outlive the decoder
    let data: [UInt8]

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

    /// Returns true if there is any data left to decode.
    public func hasNext() -> Bool {
        aws_cbor_decoder_get_remaining_length(self.rawValue) != 0
    }

    /// Decodes and returns the next value. If there is no value, this function will throw an error.
    /// You must call `hasNext()` before calling this function.
    public func popNext() throws -> CBORType {
        var cbor_type: aws_cbor_type = AWS_CBOR_TYPE_UNKNOWN
        guard aws_cbor_decoder_peek_type(self.rawValue, &cbor_type) == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }

        switch cbor_type {
        case AWS_CBOR_TYPE_UINT:
            return try decodeUInt()
        case AWS_CBOR_TYPE_NEGINT:
            return try decodeNegInt()
        case AWS_CBOR_TYPE_FLOAT:
            return try decodeFloat()
        case AWS_CBOR_TYPE_BYTES:
            return try decodeBytes()
        case AWS_CBOR_TYPE_TEXT:
            return try decodeText()
        case AWS_CBOR_TYPE_BOOL:
            return try decodeBool()
        case AWS_CBOR_TYPE_NULL:
            return try decodeNull()
        case AWS_CBOR_TYPE_TAG:
            return try decodeTag()
        case AWS_CBOR_TYPE_ARRAY_START:
            return try decodeDefiniteArray()
        case AWS_CBOR_TYPE_MAP_START:
            return try decodeDefiniteMap()
        case AWS_CBOR_TYPE_UNDEFINED:
            return try decodeUndefined()
        case AWS_CBOR_TYPE_BREAK:
            return try decodeBreak()

        case AWS_CBOR_TYPE_INDEF_ARRAY_START:
            return try decodeIndefiniteArray()
        case AWS_CBOR_TYPE_INDEF_MAP_START:
            return try decodeIndefiniteMap()
        case AWS_CBOR_TYPE_INDEF_BYTES_START:
            return try decodeIndefiniteBytes()
        case AWS_CBOR_TYPE_INDEF_TEXT_START:
            return try decodeIndefiniteText()

        default:
            throw CommonRunTimeError.crtError(CRTError(code: AWS_ERROR_CBOR_UNEXPECTED_TYPE.rawValue))
        }
    }

    // Decoding helper methods for definite and simple types
    private func decodeUInt() throws -> CBORType {
        var out_value: UInt64 = 0
        guard aws_cbor_decoder_pop_next_unsigned_int_val(self.rawValue, &out_value) == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        return .uint(out_value)
    }

    private func decodeNegInt() throws -> CBORType {
        var out_value: UInt64 = 0
        guard aws_cbor_decoder_pop_next_negative_int_val(self.rawValue, &out_value) == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        guard out_value <= Int64.max else {
            throw CommonRunTimeError.crtError(CRTError(code: AWS_ERROR_CBOR_UNEXPECTED_TYPE.rawValue))
        }
        // CBOR negative integers are encoded as -1 - value, so convert accordingly.
        return .int(Int64(-Int64(out_value) - 1))
    }

    private func decodeFloat() throws -> CBORType {
        var out_value: Double = 0
        guard aws_cbor_decoder_pop_next_float_val(self.rawValue, &out_value) == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        return .double(out_value)
    }

    private func decodeBytes() throws -> CBORType {
        var out_value = aws_byte_cursor()
        guard aws_cbor_decoder_pop_next_bytes_val(self.rawValue, &out_value) == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        return .bytes(out_value.toData())
    }

    private func decodeText() throws -> CBORType {
        var out_value = aws_byte_cursor()
        guard aws_cbor_decoder_pop_next_text_val(self.rawValue, &out_value) == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        return .text(out_value.toString())
    }

    private func decodeBool() throws -> CBORType {
        var out_value: Bool = false
        guard aws_cbor_decoder_pop_next_boolean_val(self.rawValue, &out_value) == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        return .bool(out_value)
    }

    private func decodeNull() throws -> CBORType {
        guard aws_cbor_decoder_consume_next_single_element(self.rawValue) == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        return .null
    }

    private func decodeUndefined() throws -> CBORType {
        guard aws_cbor_decoder_consume_next_single_element(self.rawValue) == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        return .undefined
    }

    private func decodeTag() throws -> CBORType {
        var out_value: UInt64 = 0
        guard aws_cbor_decoder_pop_next_tag_val(self.rawValue, &out_value) == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        guard out_value == 1 else {
            return .tag(out_value)
        }

        let timestamp = try popNext()
        switch timestamp {
        case .double(let value):
            return .date(Date(timeIntervalSince1970: value))
        case .uint(let value):
            return .date(Date(timeIntervalSince1970: Double(value)))
        case .int(let value):
            return .date(Date(timeIntervalSince1970: Double(value)))
        default:
            throw CommonRunTimeError.crtError(CRTError(code: AWS_ERROR_CBOR_UNEXPECTED_TYPE.rawValue))
        }
    }

    private func decodeDefiniteArray() throws -> CBORType {
        var length: UInt64 = 0
        guard aws_cbor_decoder_pop_next_array_start(self.rawValue, &length) == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }

        var array: [CBORType] = []
        for _ in 0..<length {
            array.append(try popNext())
        }
        return .array(array)
    }

    private func decodeDefiniteMap() throws -> CBORType {
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
    }

    // Decoding helper methods for break and indefinite types
    private func decodeBreak() throws -> CBORType {
        // This should only be called inside indefinite decoding
        guard aws_cbor_decoder_consume_next_single_element(self.rawValue) == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        return .indef_break
    }

    private func decodeIndefiniteArray() throws -> CBORType {
        guard aws_cbor_decoder_consume_next_single_element(self.rawValue) == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        var array: [CBORType] = []
        while true {
            let cbor_type = try popNext()
            if cbor_type == .indef_break {
                break
            } else {
                array.append(cbor_type)
            }
        }
        return .array(array)
    }

    private func decodeIndefiniteMap() throws -> CBORType {
        guard aws_cbor_decoder_consume_next_single_element(self.rawValue) == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        var map: [String: CBORType] = [:]
        while true {
            let keyVal = try popNext()
            if keyVal == .indef_break {
                break
            } else {
                guard case .text(let key) = keyVal else {
                    throw CommonRunTimeError.crtError(CRTError(code: AWS_ERROR_CBOR_UNEXPECTED_TYPE.rawValue))
                }

                let value = try popNext()
                map[key] = value
            }
        }
        return .map(map)
    }

    private func decodeIndefiniteBytes() throws -> CBORType {
        guard aws_cbor_decoder_consume_next_single_element(self.rawValue) == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }

        var data = Data()
        while true {
            let cbor_type = try popNext()
            if cbor_type == .indef_break {
                break
            } else {
                guard case .bytes(let chunkData) = cbor_type else {
                    throw CommonRunTimeError.crtError(CRTError(code: AWS_ERROR_CBOR_UNEXPECTED_TYPE.rawValue))
                }
                data.append(chunkData)
            }
        }
        return .bytes(data)
    }

    private func decodeIndefiniteText() throws -> CBORType {
        guard aws_cbor_decoder_consume_next_single_element(self.rawValue) == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }

        var text = ""
        while true {
            let cbor_type = try popNext()
            if cbor_type == .indef_break {
                break
            } else {
                guard case .text(let chunkStr) = cbor_type else {
                    throw CommonRunTimeError.crtError(CRTError(code: AWS_ERROR_CBOR_UNEXPECTED_TYPE.rawValue))
                }
                text += chunkStr
            }
        }
        return .text(text)
    }

    deinit {
        aws_cbor_decoder_destroy(rawValue)
    }
}
