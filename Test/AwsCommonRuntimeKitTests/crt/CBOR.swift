//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCCommon
import XCTest

@testable import AwsCommonRuntimeKit

class CBORTests: XCBaseTestCase {

    func testCBOR() async throws {
        let values_to_encode: [CBORType] = [
            .uint64(100),
            .uint64(UInt64.min),
            .uint64(UInt64.max),
            .int(-100),
            .int(Int64.min),
            .int(Int64.max),
            .double(10.59),
            .double(10.0),
            .bytes("hello".data(using: .utf8)!),
            .text("hello"),
            .bool(true),
            .null,
            .undefined,
            .date(Date(timeIntervalSince1970: 10.5)),
            .array([.int(-100), .uint64(1000)]),
            .map(["key": .uint64(100), "key2": .int(-100)]),
            .indef_array_start,
            .uint64(100),
            .int(-100),
            .indef_break,
            .indef_map_start,
            .text("key1"),
            .uint64(100),
            .text("key2"),
            .int(-100),
            .indef_break,
            .indef_text_start,
            .text("hello"),
            .indef_break,
            .indef_bytes_start,
            .int(-100),
            .indef_break,
        ]
        let expected_decoded_values: [CBORType] = [
            .uint64(100),
            .uint64(UInt64.min),
            .uint64(UInt64.max),
            .int(-100),
            .int(Int64.min),
            .uint64(UInt64(Int64.max)),
            .double(10.59),
            .uint64(10),
            .bytes("hello".data(using: .utf8)!),
            .text("hello"),
            .bool(true),
            .null,
            .undefined,
            .date(Date(timeIntervalSince1970: 10.5)),
            .array([.int(-100), .uint64(1000)]),
            .map(["key": .uint64(100), "key2": .int(-100)]),
            .indef_array_start,
            .uint64(100),
            .int(-100),
            .indef_break,
            .indef_map_start,
            .text("key1"),
            .uint64(100),
            .text("key2"),
            .int(-100),
            .indef_break,
            .indef_text_start,
            .text("hello"),
            .indef_break,
            .indef_bytes_start,
            .int(-100),
            .indef_break,
        ]


        // encode the values. Drop the encoder to verify lifetime semantics.
        var encoded: [UInt8] = []
        do {
            let encoder = try! CBOREncoder()
            for value in values_to_encode {
                encoder.encode(value)
            }
            encoded = encoder.getEncoded()
        }

        // decode the values
        let decoder = try! CBORDecoder(data: encoded)
        for value in expected_decoded_values {
            XCTAssertTrue(decoder.hasNext())
            XCTAssertEqual(try! decoder.popNext(), value)
        }
        XCTAssertFalse(decoder.hasNext())
    }

}
