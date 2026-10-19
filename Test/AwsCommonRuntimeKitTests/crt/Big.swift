//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCCommon
import XCTest

@testable import AwsCommonRuntimeKit

class BigTests: XCBaseTestCase {

  func testBigIntegerRoundTrip() throws {
    let huge = "-123456789012345678901234567890123456789012345678901234567890"
    let value = try BigInteger(huge)
    XCTAssertTrue(value.isNegative)
    XCTAssertFalse(value.isZero)
    XCTAssertEqual(try value.toString(), huge)
    XCTAssertEqual(value.description, huge)

    // Leading zeros are dropped and zero is never negative.
    let zero = try BigInteger("-000")
    XCTAssertTrue(zero.isZero)
    XCTAssertFalse(zero.isNegative)
    XCTAssertEqual(zero.description, "0")

    XCTAssertEqual(try BigInteger(Int64.min).description, "-9223372036854775808")
  }

  func testBigIntegerInvalidInput() throws {
    for input in ["", "12x", " 1", "1 ", "--1", "0x10"] {
      XCTAssertThrowsError(try BigInteger(input), "\(input)") { error in
        guard case CommonRunTimeError.crtError(let crtError) = error else {
          return XCTFail("unexpected error \(error)")
        }
        XCTAssertEqual(crtError.code, Int32(AWS_ERROR_INVALID_ARGUMENT.rawValue))
      }
    }
  }

  func testBigIntegerEquality() throws {
    let a = try BigInteger("-123456789012345678901234567890")
    XCTAssertEqual(a, try BigInteger("-000123456789012345678901234567890"))
    XCTAssertNotEqual(a, try BigInteger("123456789012345678901234567890"))
    XCTAssertNotEqual(a, try BigInteger("-123456789012345678901234567891"))
    XCTAssertEqual(try BigInteger(0), try BigInteger("-0"))
  }

  func testBigDecimal() throws {
    let value = try BigDecimal("1.50")
    XCTAssertEqual(value.exponent, -2)
    XCTAssertEqual(value.mantissa.description, "150")
    XCTAssertEqual(value.description, "150e-2")

    // Scale is preserved, so these are different values.
    XCTAssertNotEqual(value, try BigDecimal("1.5"))
    XCTAssertEqual(value, try BigDecimal("150e-2"))

    let parts = try BigDecimal(mantissa: try BigInteger(12345), exponent: -2)
    XCTAssertEqual(parts.description, "12345e-2")

    XCTAssertThrowsError(try BigDecimal("1e"))
  }

  func testBigDecimalMantissaOutlivesDecimal() throws {
    var mantissa: BigInteger? = nil
    do {
      let temp = try BigDecimal("-7e3")
      mantissa = temp.mantissa
    }
    XCTAssertEqual(mantissa?.description, "-7")
  }
}
