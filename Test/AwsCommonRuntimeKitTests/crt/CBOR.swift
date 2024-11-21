//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
import AwsCCommon
@testable import AwsCommonRuntimeKit

class CBORTests: XCBaseTestCase {

    func testCBOR() async throws {
        let values: [CBORType] = [
            .uint64(100),
            .int(-100),
            .double(10.59),
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
        // encode the values
        let encoder = CBOREncoder()
        for value in values {
            encoder.encode(value)
        }
        let encoded = encoder.getEncoded();

        print(encoded)

        let decoder = CBORDecoder(data: encoded)
        for value in values {
            XCTAssertTrue(decoder.hasNext())
            XCTAssertEqual(try! decoder.decodeNext(), value)
        }
        XCTAssertFalse(decoder.hasNext())
    }

}
