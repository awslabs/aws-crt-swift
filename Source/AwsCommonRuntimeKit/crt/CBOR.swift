import AwsCCommon
//  SPDX-License-Identifier: Apache-2.0.
import Foundation

public class CBOREncoder {
    var rawValue: OpaquePointer

    public init() {
        // TODO: Try init?
        rawValue = aws_cbor_encoder_new(allocator.rawValue)!
    }

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
        //case .cbor_break: aws_cbor_encoder_write_break(self.rawValue)
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
        case .timestamp(let value):
            do {
                // tag 1 means epoch based timestamp
                aws_cbor_encoder_write_tag(self.rawValue, 1)
                aws_cbor_encoder_write_float(self.rawValue, value.timeIntervalSince1970)
            }
        case .undefined: aws_cbor_encoder_write_undefined(self.rawValue)
        }
    }

    public func getEncoded() -> Data {
        aws_cbor_encoder_get_encoded_data(self.rawValue).toData()
    }

    deinit {
        aws_cbor_encoder_destroy(rawValue)
    }
}

public enum CBORType: Equatable {
    case uint64(_ value: UInt64)
    case int(_ value: Int64)
    case double(_ value: Double)
    case bytes(_ value: Data)
    case text(_ value: String)
    case array(_ value: [CBORType])
    case map(_ value: [String: CBORType])
    case timestamp(_ value: Date)
    case bool(_ value: Bool)
    case null
    case undefined
    //case cbor_break
    // ask if they need unbounded arrays, map, text, bytes
}

public class CBORDecoder {
    var rawValue: OpaquePointer
    // Keep a reference to data to make it outlive the decoder
    let data: Data

    public init(data: Data) {
        // TODO: Try init?
        self.data = data
        rawValue = self.data.withAWSByteCursorPointer {
            aws_cbor_decoder_new(allocator.rawValue, $0.pointee)!
        }
    }

    public func decodeNext() throws -> CBORType {
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
        default:
            fatalError("invalid cbor decode type")
        }
    }

    public func hasNext() -> Bool {
        aws_cbor_decoder_get_remaining_length(self.rawValue) != 0
    }

    deinit {
        aws_cbor_decoder_destroy(rawValue)
    }
}
