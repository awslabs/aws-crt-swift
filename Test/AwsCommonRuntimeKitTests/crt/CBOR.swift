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
      .bytes(Data([0x01, 0x02, 0x03])),  // First chunk of bytes
      .bytes(Data([0x04, 0x05])),  // Second chunk of bytes
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
      // test that tag 1 is decoded as date
      .date(Date(timeIntervalSince1970: 10.5)),
      .date(Date(timeIntervalSince1970: 20.5)),
      // complex types
      .array([.int(-100), .uint(1000)]),
      .map(["key": .uint(100), "key2": .int(-100)]),
      .bytes("hello".data(using: .utf8)!),
      .text("hello"),
      // indef types
      .array([.uint(100), .int(-100)]),
      .map(["key1": .uint(100), "key2": .int(-100)]),
      .text("hello"),
      .bytes(Data([0x01, 0x02, 0x03, 0x04, 0x05])),
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
    for expected in expected_decoded_values {
      XCTAssertTrue(decoder.hasNext())
      let actual = try! decoder.popNext()
      XCTAssertEqual(actual, expected)
    }
    XCTAssertFalse(decoder.hasNext())
  }

  func testCBORNoRollup() async throws {
    // Used in both tests below
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
      .array_start(2),
      .int(-100),
      .uint(1000),
      .map_start(2),
      .text("key"),
      .uint(100),
      .text("key2"),
      .int(-100),
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
      .bytes(Data([0x01, 0x02, 0x03])),  // First chunk of bytes
      .bytes(Data([0x04, 0x05])),  // Second chunk of bytes
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
      // test that tag 1 is decoded as date
      .date(Date(timeIntervalSince1970: 10.5)),
      .date(Date(timeIntervalSince1970: 20.5)),
      // complex types
      .array_start(2),
      .int(-100),
      .uint(1000),
      .map_start(2),
      .text("key"),
      .uint(100),
      .text("key2"),
      .int(-100),
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
      .text("hello"),
      .bytes(Data([0x01, 0x02, 0x03, 0x04, 0x05])),
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

    // decode the values using the rollupCollections: false option on the
    // decoder to prevent maps & arrays from being "rolled up"
    let decoder = try! CBORDecoder(data: encoded, rollupCollections: false)
    for expected in expected_decoded_values {
      XCTAssertTrue(decoder.hasNext())
      let actual = try! decoder.popNext()
      XCTAssertEqual(actual, expected)
    }
    XCTAssertFalse(decoder.hasNext())
  }

  func test_isNull_trueCase() throws {
    let encoder = try! CBOREncoder()
    let element = CBORType.null
    encoder.encode(element)

    let decoder = try CBORDecoder(data: encoder.getEncoded())
    XCTAssertTrue(try decoder.isNull())

    let next = try decoder.popNext()
    XCTAssertEqual(next, element)
  }

  func test_isNull_falseCase() throws {
    let encoder = try! CBOREncoder()
    let element = CBORType.uint(123)
    encoder.encode(element)

    let decoder = try CBORDecoder(data: encoder.getEncoded())
    XCTAssertFalse(try decoder.isNull())

    let next = try decoder.popNext()
    XCTAssertEqual(next, element)
  }

  func test_isIndefBreak_trueCase() throws {
    let encoder = try! CBOREncoder()
    let element = CBORType.indef_break
    encoder.encode(element)

    let decoder = try CBORDecoder(data: encoder.getEncoded())
    XCTAssertTrue(try decoder.isIndefBreak())

    let next = try decoder.popNext()
    XCTAssertEqual(next, element)
  }

  func test_isIndefBreak_falseCase() throws {
    let encoder = try! CBOREncoder()
    let element = CBORType.uint(456)
    encoder.encode(element)

    let decoder = try CBORDecoder(data: encoder.getEncoded())
    XCTAssertFalse(try decoder.isIndefBreak())

    let next = try decoder.popNext()
    XCTAssertEqual(next, element)
  }

  func test_depthLimit_rejectsDeepNesting() throws {
    // 129 nested arrays of length 1: [[[...[1]...]]]
    // Each 0x81 = definite array of 1 element
    var data: [UInt8] = Array(repeating: 0x81, count: 129)
    data.append(0x01)  // innermost value: uint 1

    let decoder = try CBORDecoder(data: data)
    XCTAssertThrowsError(try decoder.popNext()) { error in
      // Should fail due to depth limit exceeded
      XCTAssertTrue(error is CommonRunTimeError)
    }
  }

  func testBigIntegerRoundTrip() throws {
    // Values that fit in 64 bits come back as plain integers. Larger ones come back as bignums.
    let cases: [(String, CBORType?)] = [
      ("0", .uint(0)),
      ("-1", .int(-1)),
      ("18446744073709551615", .uint(UInt64.max)),
      ("-9223372036854775808", .int(Int64.min)),
      ("18446744073709551616", nil),
      ("-18446744073709551617", nil),
      ("123456789012345678901234567890123456789012345678901234567890", nil),
    ]

    let encoder = try CBOREncoder()
    for (input, _) in cases {
      encoder.encode(.bigInteger(try BigInteger(input)))
    }

    let decoder = try CBORDecoder(data: encoder.getEncoded())
    for (input, plain) in cases {
      let decoded = try decoder.popNext()
      if let plain {
        XCTAssertEqual(decoded, plain)
      } else {
        XCTAssertEqual(decoded, .bigInteger(try BigInteger(input)))
      }
    }
    XCTAssertFalse(decoder.hasNext())
  }

  func testPopNextBigIntegerReadsAnyInteger() throws {
    let encoder = try CBOREncoder()
    encoder.encode(.uint(42))
    encoder.encode(.int(-42))
    encoder.encode(.bigInteger(try BigInteger("-18446744073709551617")))

    let decoder = try CBORDecoder(data: encoder.getEncoded())
    XCTAssertEqual(try decoder.popNextBigInteger().toString(), "42")
    XCTAssertEqual(try decoder.popNextBigInteger().toString(), "-42")
    XCTAssertEqual(try decoder.popNextBigInteger().toString(), "-18446744073709551617")
  }

  func testBigDecimalRoundTrip() throws {
    let inputs = ["150e-2", "1e3", "-12345678901234567890123456789e-40", "0e0"]

    let encoder = try CBOREncoder()
    for input in inputs {
      encoder.encode(.bigDecimal(try BigDecimal(input)))
    }

    let decoder = try CBORDecoder(data: encoder.getEncoded())
    for input in inputs {
      XCTAssertEqual(try decoder.popNext(), .bigDecimal(try BigDecimal(input)))
    }
    XCTAssertFalse(decoder.hasNext())
  }

  func testBigDecimalInsideCollections() throws {
    let encoder = try CBOREncoder()
    encoder.encode(
      .map([
        "price": .bigDecimal(try BigDecimal("19.99")),
        "ids": .array([.bigInteger(try BigInteger("18446744073709551616")), .uint(1)]),
      ]))

    let decoder = try CBORDecoder(data: encoder.getEncoded())
    XCTAssertEqual(
      try decoder.popNext(),
      .map([
        "price": .bigDecimal(try BigDecimal("19.99")),
        "ids": .array([.bigInteger(try BigInteger("18446744073709551616")), .uint(1)]),
      ]))
  }

  func testMalformedBigTagsStayTags() throws {
    // A tag 2 or 4 whose content isn't a bignum or decimal fraction is still returned as a plain tag,
    // followed by its content, as it was before big numbers were supported.
    let encoder = try CBOREncoder()
    encoder.encode(.tag(2))
    encoder.encode(.text("x"))
    encoder.encode(.tag(4))
    encoder.encode(.uint(7))

    let decoder = try CBORDecoder(data: encoder.getEncoded())
    XCTAssertEqual(try decoder.popNext(), .tag(2))
    XCTAssertEqual(try decoder.popNext(), .text("x"))
    XCTAssertEqual(try decoder.popNext(), .tag(4))
    XCTAssertEqual(try decoder.popNext(), .uint(7))
  }
}
