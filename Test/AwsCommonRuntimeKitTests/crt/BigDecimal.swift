//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCCommon
import XCTest

@testable import AwsCommonRuntimeKit

class BigDecimalTests: XCBaseTestCase {

  func testBigDecimal() throws {
    let value = try BigDecimal("1.50")
    XCTAssertEqual(value.description, "150e-2")

    // Scale is preserved, so these are different values.
    XCTAssertNotEqual(value, try BigDecimal("1.5"))
    XCTAssertEqual(value, try BigDecimal("150e-2"))

    XCTAssertThrowsError(try BigDecimal("1e"))
  }

  func testBigDecimalRoundTrip() throws {
    let cases = [
      ("0", "0e0"),
      ("-0", "0e0"),
      ("+1.0", "10e-1"),
      ("-0.5", "-5e-1"),
      ("123.45E-2", "12345e-4"),
      ("1e+3", "1e3"),
      ("12345678901234567890.123456789", "12345678901234567890123456789e-9"),
      ("1e9223372036854775807", "1e9223372036854775807"),
    ]
    for (input, expected) in cases {
      let value = try BigDecimal(input)
      XCTAssertEqual(try value.toString(), expected, input)
      XCTAssertEqual(value, try BigDecimal(expected), input)
    }
  }

  func testBigDecimalInvalidInput() throws {
    for input in ["", "12x", " 1", "1.", ".5", "1e", "e5", "1e+"] {
      XCTAssertThrowsError(try BigDecimal(input), "\(input)") { error in
        guard case CommonRunTimeError.crtError(let crtError) = error else {
          return XCTFail("unexpected error \(error)")
        }
        XCTAssertEqual(crtError.code, Int32(AWS_ERROR_INVALID_ARGUMENT.rawValue), input)
      }
    }
  }

  func testBigDecimalExponentOverflow() throws {
    XCTAssertThrowsError(try BigDecimal("1e9223372036854775808")) { error in
      guard case CommonRunTimeError.crtError(let crtError) = error else {
        return XCTFail("unexpected error \(error)")
      }
      XCTAssertEqual(crtError.code, Int32(AWS_ERROR_OVERFLOW_DETECTED.rawValue))
    }
  }

  func testBigDecimalEquality() throws {
    let a = try BigDecimal("-1.2345e10")
    XCTAssertEqual(a, try BigDecimal("-12345e6"))
    XCTAssertNotEqual(a, try BigDecimal("1.2345e10"))
    XCTAssertNotEqual(a, try BigDecimal("-12345e7"))
    XCTAssertNotEqual(try BigDecimal("1e3"), try BigDecimal("1000"))
  }
}
