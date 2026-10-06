//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCCommon
import Foundation

/// Arbitrary-precision signed integer. Immutable.
///
/// The magnitude of every value is below 2^65536 (19,729 decimal digits). Constructing a value outside
/// that range throws a CRT error with code `AWS_ERROR_OVERFLOW_DETECTED`.
public final class BigInteger: Equatable, CustomStringConvertible, @unchecked Sendable {
  let rawValue: OpaquePointer
  /// Set when `rawValue` is owned by another object (a `BigDecimal` mantissa). Holding it keeps `rawValue` alive.
  private let owner: AnyObject?

  /// Takes ownership of a `aws_big_integer` created by the C library.
  init(rawValue: OpaquePointer) {
    self.rawValue = rawValue
    self.owner = nil
  }

  /// Wraps a `aws_big_integer` that is owned by `owner` and valid for as long as `owner` is alive.
  init(borrowing rawValue: OpaquePointer, owner: AnyObject) {
    self.rawValue = rawValue
    self.owner = owner
  }

  /// Parses a base-10 integer. The grammar is `["-" / "+"] [0-9]+`. Whitespace is not accepted.
  /// - Throws: `CommonRunTimeError.crtError`
  public convenience init(_ string: String) throws {
    let rawValue = string.withByteCursor { cursor in
      aws_big_integer_new_from_cursor(allocator.rawValue, cursor)
    }
    guard let rawValue else {
      throw CommonRunTimeError.crtError(.makeFromLastError())
    }
    self.init(rawValue: rawValue)
  }

  public convenience init(_ value: Int64) throws {
    guard let rawValue = aws_big_integer_new_from_i64(allocator.rawValue, value) else {
      throw CommonRunTimeError.crtError(.makeFromLastError())
    }
    self.init(rawValue: rawValue)
  }

  public var isNegative: Bool {
    aws_big_integer_is_negative(rawValue)
  }

  public var isZero: Bool {
    aws_big_integer_is_zero(rawValue)
  }

  /// The base-10 representation.
  /// - Throws: `CommonRunTimeError.crtError`
  public func toString() throws -> String {
    try withByteBuf { buf in aws_big_integer_to_str(rawValue, &buf) }.toString()
  }

  public var description: String {
    (try? toString()) ?? "<invalid>"
  }

  /// Numeric equality.
  public static func == (lhs: BigInteger, rhs: BigInteger) -> Bool {
    if lhs === rhs {
      return true
    }
    return aws_big_integer_eq(lhs.rawValue, rhs.rawValue)
  }

  deinit {
    if owner == nil {
      aws_big_integer_destroy(rawValue)
    }
  }
}

/// Arbitrary-precision decimal with value `mantissa * 10^exponent`. Immutable.
///
/// Scale is preserved: `"1.50"` is mantissa 150 and exponent -2, and is not equal to `"1.5"`.
public final class BigDecimal: Equatable, CustomStringConvertible, @unchecked Sendable {
  let rawValue: OpaquePointer

  /// Takes ownership of a `aws_big_decimal` created by the C library.
  init(rawValue: OpaquePointer) {
    self.rawValue = rawValue
  }

  /// Parses a decimal number: an optional sign, digits, an optional fraction, and an optional exponent.
  /// Whitespace is not accepted.
  /// - Throws: `CommonRunTimeError.crtError`
  public convenience init(_ string: String) throws {
    let rawValue = string.withByteCursor { cursor in
      aws_big_decimal_new_from_cursor(allocator.rawValue, cursor)
    }
    guard let rawValue else {
      throw CommonRunTimeError.crtError(.makeFromLastError())
    }
    self.init(rawValue: rawValue)
  }

  /// Creates a decimal with value `mantissa * 10^exponent`. The scale is taken as given.
  /// - Throws: `CommonRunTimeError.crtError`
  public convenience init(mantissa: BigInteger, exponent: Int64) throws {
    guard
      let rawValue = aws_big_decimal_new_from_parts(allocator.rawValue, mantissa.rawValue, exponent)
    else {
      throw CommonRunTimeError.crtError(.makeFromLastError())
    }
    self.init(rawValue: rawValue)
  }

  public var mantissa: BigInteger {
    // The C mantissa is owned by the decimal, so the returned value keeps this decimal alive.
    BigInteger(borrowing: aws_big_decimal_get_mantissa(rawValue)!, owner: self)
  }

  public var exponent: Int64 {
    aws_big_decimal_get_exponent(rawValue)
  }

  /// The representation `<mantissa>e<exponent>`, for example `"12345e-2"`.
  /// - Throws: `CommonRunTimeError.crtError`
  public func toString() throws -> String {
    try withByteBuf { buf in aws_big_decimal_to_str(rawValue, &buf) }.toString()
  }

  public var description: String {
    (try? toString()) ?? "<invalid>"
  }

  /// Structural equality: same exponent and same mantissa.
  public static func == (lhs: BigDecimal, rhs: BigDecimal) -> Bool {
    if lhs === rhs {
      return true
    }
    guard lhs.exponent == rhs.exponent else {
      return false
    }
    return lhs.mantissa == rhs.mantissa
  }

  deinit {
    aws_big_decimal_destroy(rawValue)
  }
}

/// Runs `body` against a growable buffer and returns the buffer contents.
private func withByteBuf(_ body: (inout aws_byte_buf) -> Int32) throws -> Data {
  var buf = aws_byte_buf()
  guard aws_byte_buf_init(&buf, allocator.rawValue, 64) == AWS_OP_SUCCESS else {
    throw CommonRunTimeError.crtError(.makeFromLastError())
  }
  defer { aws_byte_buf_clean_up(&buf) }

  guard body(&buf) == AWS_OP_SUCCESS else {
    throw CommonRunTimeError.crtError(.makeFromLastError())
  }
  return buf.toData()
}

extension Data {
  fileprivate func toString() -> String {
    String(decoding: self, as: UTF8.self)
  }
}
