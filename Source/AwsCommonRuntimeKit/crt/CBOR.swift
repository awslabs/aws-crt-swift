//  SPDX-License-Identifier: Apache-2.0.
import Foundation
import AwsCCommon

public struct CBOREncoder {
    var rawValue: OpaquePointer

    public init() {
        // TODO: Try init?
        rawValue = aws_cbor_encoder_new(allocator.rawValue)!
    }

    public func encode(value: CBORType) {
        switch value {
        case .uint64(let value): aws_cbor_encoder_write_uint(self.rawValue, value)
        case .int(let value): {
            let value = value > 0 ? value : -1 - value
            aws_cbor_encoder_write_uint(self.rawValue, UInt64(value))
        }
        case .double(let value): aws_cbor_encoder_write_float(self.rawValue, value)
        // case .bytes(let value):
        // case .text(let value):
        }
    }

    deinit {
        aws_cbor_encoder_destroy(rawValue)
    }
}

public enum CBORType: Equatable {
    case uint64(value: UInt64)
    case int(value: Int64)  // NegInt?
    case double(value: Double)  // float 32 or 64?
    // case bytes(value: [uint8])
    // case text(value: String)
    // case timestamp(value: xyz)
    // TODO: More types
    // TODO: How to handle map and other stuff?
}
