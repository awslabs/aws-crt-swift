//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
import Foundation
@testable import AwsCommonRuntimeKit

class AWSEndpointPropertyTests: XCTestCase {
    func testDecoderWithBool() throws {
        let data = "true".data(using: .utf8)!
        let actual = try JSONDecoder().decode(AWSEndpointProperty.self, from: data)
        XCTAssertEqual(true, actual.toAnyHashable())
    }
    
    func testDecoderWithString() throws {
        let data = "\"hello\"".data(using: .utf8)!
        let actual = try JSONDecoder().decode(AWSEndpointProperty.self, from: data)
        XCTAssertEqual("hello", actual.toAnyHashable())
    }

    func testDecoderWithArray() throws {
        let data = "[\"hello\", \"world\"]".data(using: .utf8)!
        let actual = try JSONDecoder().decode(AWSEndpointProperty.self, from: data)
        XCTAssertEqual(["hello", "world"], actual.toAnyHashable())
    }

    func testDecoderWithDictionary() throws {
        let data = "{\"hello\": \"world\"}".data(using: .utf8)!
        let actual = try JSONDecoder().decode(AWSEndpointProperty.self, from: data)
        XCTAssertEqual(["hello": "world"], actual.toAnyHashable())
    }

    func testDecoderWithMixed() throws {
        let data = "{\"hello\": [\"world\", \"universe\"], \"isAlive\": true}".data(using: .utf8)!
        let actual = try JSONDecoder().decode(AWSEndpointProperty.self, from: data)
        let expected: [String: AnyHashable] = [
            "hello": [
                "world",
                "universe"
            ],
            "isAlive": true
        ]
        XCTAssertEqual(expected, actual.toAnyHashable())
    }
}
