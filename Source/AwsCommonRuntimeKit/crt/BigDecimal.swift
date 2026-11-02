//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCCommon
import Foundation

/// Arbitrary-precision decimal, with value `mantissa * 10^exponent`. Immutable.
///
/// Scale is preserved: `"1.50"` is mantissa 150 and exponent -2, and is not equal to `"1.5"`.
///
/// Math operations are not supported, use `toString()` to export to a library that does.
public final class BigDecimal: Equatable, CustomStringConvertible, @unchecked Sendable {
  let rawValue: OpaquePointer

  /// Takes ownership of a `aws_big_decimal` created by the C library.
  init(rawValue: OpaquePointer) {
    self.rawValue = rawValue
  }

  /// Parses a decimal number: an optional sign, digits, an optional fraction, and an optional exponent.
  /// The grammar is `["-" / "+"] [0-9]+ ["." [0-9]+] ["e" ["-" / "+"] [0-9]+]`. Whitespace is not accepted.
  /// - Throws: `CommonRunTimeError.crtError`. The code is `AWS_ERROR_INVALID_ARGUMENT` if the input is malformed,
  ///   and `AWS_ERROR_OVERFLOW_DETECTED` if the exponent does not fit in an `Int64`.
  public convenience init(_ string: String) throws {
    let rawValue = string.withByteCursor { cursor in
      aws_big_decimal_new_from_cursor(allocator.rawValue, cursor)
    }
    guard let rawValue else {
      throw CommonRunTimeError.crtError(.makeFromLastError())
    }
    self.init(rawValue: rawValue)
  }

  /// The representation `<mantissa>e<exponent>`, for example `"12345e-2"`.
  /// - Throws: `CommonRunTimeError.crtError`
  public func toString() throws -> String {
    try withOutputBuffer(capacity: aws_big_decimal_max_strlen(rawValue)) { buf in
      aws_byte_buf_append_big_decimal(&buf, rawValue)
    }
  }

  public var description: String {
    (try? toString()) ?? "<invalid>"
  }

  /// Structural equality: same exponent and same mantissa.
  public static func == (lhs: BigDecimal, rhs: BigDecimal) -> Bool {
    if lhs === rhs {
      return true
    }
    return aws_big_decimal_eq(lhs.rawValue, rhs.rawValue)
  }

  deinit {
    aws_big_decimal_destroy(rawValue)
  }
}
