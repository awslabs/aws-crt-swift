//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
import Foundation
@testable import AwsCommonRuntimeKit

class EndpointPropertyTests: XCTestCase {
    func testBool() throws {
        let data = "true".data(using: .utf8)!
        let actual = try JSONDecoder().decode(EndpointProperty.self, from: data)
        XCTAssertEqual(true, actual.toAnyHashable())
    }
    
    func testString() throws {
        let data = "\"hello\"".data(using: .utf8)!
        let actual = try JSONDecoder().decode(EndpointProperty.self, from: data)
        XCTAssertEqual("hello", actual.toAnyHashable())
    }

    func testArray() throws {
        let data = "[\"hello\", \"world\"]".data(using: .utf8)!
        let actual = try JSONDecoder().decode(EndpointProperty.self, from: data)
        XCTAssertEqual(["hello", "world"], actual.toAnyHashable())
    }

    func testDictionary() throws {
        let data = "{\"hello\": \"world\"}".data(using: .utf8)!
        let actual = try JSONDecoder().decode(EndpointProperty.self, from: data)
        XCTAssertEqual(["hello": "world"], actual.toAnyHashable())
    }

    func testMixed() throws {
        let data = "{\"hello\": [\"world\", \"universe\"]}".data(using: .utf8)!
        let actual = try JSONDecoder().decode(EndpointProperty.self, from: data)
        XCTAssertEqual(["hello": ["world", "universe"]], actual.toAnyHashable())
    }
}
