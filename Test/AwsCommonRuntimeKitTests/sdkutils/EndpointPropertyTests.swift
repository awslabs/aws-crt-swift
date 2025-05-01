//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import Foundation
import XCTest

@testable import AwsCommonRuntimeKit

class EndpointPropertyTests: XCTestCase {
  func testDecoderWithBool() throws {
    let data = "true".data(using: .utf8)!
    let actual = try JSONDecoder().decode(EndpointProperty.self, from: data)
    XCTAssertEqual(.bool(true), actual)
  }

  func testDecoderWithString() throws {
    let data = "\"hello\"".data(using: .utf8)!
    let actual = try JSONDecoder().decode(EndpointProperty.self, from: data)
    XCTAssertEqual(.string("hello"), actual)
  }

  func testDecoderWithArray() throws {
    let data = "[\"hello\", \"world\"]".data(using: .utf8)!
    let actual = try JSONDecoder().decode(EndpointProperty.self, from: data)
    XCTAssertEqual(.array([.string("hello"), .string("world")]), actual)
  }

  func testDecoderWithDictionary() throws {
    let data = "{\"hello\": \"world\"}".data(using: .utf8)!
    let actual = try JSONDecoder().decode(EndpointProperty.self, from: data)
    XCTAssertEqual(.dictionary(["hello": .string("world")]), actual)
  }

  func testDecoderWithMixed() throws {
    let data = "{\"hello\": [\"world\", \"universe\"], \"isAlive\": true}".data(using: .utf8)!
    let actual = try JSONDecoder().decode(EndpointProperty.self, from: data)

    let expected: EndpointProperty = .dictionary([
      "hello": .array([
        .string("world"),
        .string("universe"),
      ]),
      "isAlive": .bool(true),
    ])

    XCTAssertEqual(expected, actual)
  }
}
