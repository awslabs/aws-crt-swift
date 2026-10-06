//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCCommon
import Foundation

/// Arbitrary-precision signed integer. Immutable.
///
/// Math operations are not supported, use `toString()` to export to a library that does.
public final class BigInteger: Equatable, CustomStringConvertible, @unchecked Sendable {
  let rawValue: OpaquePointer

  /// Takes ownership of a `aws_big_integer` created by the C library.
  init(rawValue: OpaquePointer) {
    self.rawValue = rawValue
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

  /// The base-10 representation.
  /// - Throws: `CommonRunTimeError.crtError`
  public func toString() throws -> String {
    try withOutputBuffer(capacity: aws_big_integer_max_strlen(rawValue)) { buf in
      aws_byte_buf_append_big_integer(&buf, rawValue)
    }
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
    aws_big_integer_destroy(rawValue)
  }
}

/// Runs `body` against a growable buffer with the given initial capacity and returns the buffer contents as a
/// string.
func withOutputBuffer(capacity: Int, _ body: (inout aws_byte_buf) -> Int32) throws -> String {
  var buf = aws_byte_buf()
  guard aws_byte_buf_init(&buf, allocator.rawValue, max(capacity, 1)) == AWS_OP_SUCCESS else {
    throw CommonRunTimeError.crtError(.makeFromLastError())
  }
  defer { aws_byte_buf_clean_up(&buf) }

  guard body(&buf) == AWS_OP_SUCCESS else {
    throw CommonRunTimeError.crtError(.makeFromLastError())
  }
  return String(decoding: buf.toData(), as: UTF8.self)
}
