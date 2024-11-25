//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCCommon
import XCTest

@testable import AwsCommonRuntimeKit

class CBORTests: XCBaseTestCase {

    func testCBOR() async throws {
        let values_to_encode: [CBORType] = [
            // simple types
            .uint(100),
            .uint(UInt64.min),
            .uint(UInt64.max),
            .int(-100),
            .int(Int64.min),
            .int(Int64.max),
            .double(10.59),
            .double(10.0),
            .bool(true),
            .null,
            .undefined,
            // test tag
            .tag(0),
            .uint(100),
            // test that tag 1 is decoded as date
            .tag(1),
            .double(Date(timeIntervalSince1970: 10.5).timeIntervalSince1970),
            .date(Date(timeIntervalSince1970: 20.5)),
            // complex types
            .array([.int(-100), .uint(1000)]),
            .map(["key": .uint(100), "key2": .int(-100)]),
            .bytes("hello".data(using: .utf8)!),
            .text("hello"),
            // indef types
            .indef_array_start,
            .uint(100),
            .int(-100),
            .indef_break,
            .indef_map_start,
            .text("key1"),
            .uint(100),
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
            // simple types
            .uint(100),
            .uint(UInt64.min),
            .uint(UInt64.max),
            .int(-100),
            .int(Int64.min),
            .uint(UInt64(Int64.max)),
            .double(10.59),
            .uint(10),
            .bool(true),
            .null,
            .undefined,
            // test tag
            .tag(0),
            .uint(100),
            .date(Date(timeIntervalSince1970: 10.5)),
            .date(Date(timeIntervalSince1970: 20.5)),
            // complex types
            .array([.int(-100), .uint(1000)]),
            .map(["key": .uint(100), "key2": .int(-100)]),
            .bytes("hello".data(using: .utf8)!),
            .text("hello"),
            // indef types
            .indef_array_start,
            .uint(100),
            .int(-100),
            .indef_break,
            .indef_map_start,
            .text("key1"),
            .uint(100),
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
