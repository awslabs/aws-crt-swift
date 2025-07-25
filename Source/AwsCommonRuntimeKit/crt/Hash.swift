import AwsCCal

import struct Foundation.Data
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import struct Foundation.Date
import struct Foundation.TimeInterval

public enum HashAlgorithm {
  case SHA1
  case SHA256
  case MD5

  var size: Int {
    switch self {
    case .SHA1:
      return Int(AWS_SHA1_LEN)
    case .SHA256:
      return Int(AWS_SHA256_LEN)
    case .MD5:
      return Int(AWS_MD5_LEN)
    }
  }
}

public class Hash {
  let rawValue: UnsafeMutablePointer<aws_hash>
  let algorithm: HashAlgorithm
  public init(algorithm: HashAlgorithm) {
    self.algorithm = algorithm
    switch algorithm {
    case .SHA1:
      rawValue = aws_sha1_new(allocator.rawValue)
    case .SHA256:
      rawValue = aws_sha256_new(allocator.rawValue)
    case .MD5:
      rawValue = aws_md5_new(allocator.rawValue)
    }
  }

  public func update(data: Data) throws {
    try data.withUnsafeBytes { bufferPointer in
      var byteCursor = aws_byte_cursor_from_array(bufferPointer.baseAddress, data.count)
      guard aws_hash_update(rawValue, &byteCursor) == AWS_OP_SUCCESS else {
        throw CommonRunTimeError.crtError(.makeFromLastError())
      }
    }
  }

  public func finalize(truncateTo: Int = 0) throws -> Data {
    var bufferData = Data(count: algorithm.size)
    try bufferData.withUnsafeMutableBytes { bufferPointer in
      var buffer = aws_byte_buf_from_empty_array(bufferPointer.baseAddress, algorithm.size)
      guard aws_hash_finalize(rawValue, &buffer, truncateTo) == AWS_OP_SUCCESS else {
        throw CommonRunTimeError.crtError(.makeFromLastError())
      }
    }
    return bufferData
  }

  deinit {
    aws_hash_destroy(rawValue)
  }

}

extension Data {

  /// Computes the md5 hash over data. Use this if you don't need to stream the data you're hashing and you can load
  /// the entire input to hash into memory.
  /// - Parameter truncateTo: If you specify truncate something other than 0, the output will be truncated to that number of bytes.
  public func computeMD5(truncateTo: Int = 0) throws -> Data {
    try self.withUnsafeBytes { bufferPointer in
      var byteCursor = aws_byte_cursor_from_array(bufferPointer.baseAddress, count)
      let bufferSize = 16
      var bufferData = Data(count: bufferSize)
      try bufferData.withUnsafeMutableBytes { bufferPointer in
        var buffer = aws_byte_buf_from_empty_array(bufferPointer.baseAddress, bufferSize)
        guard
          aws_md5_compute(allocator.rawValue, &byteCursor, &buffer, truncateTo) == AWS_OP_SUCCESS
        else {
          throw CommonRunTimeError.crtError(.makeFromLastError())
        }
      }
      return bufferData
    }
  }

  /// Computes the sha256 hash over data.
  /// - Parameter truncateTo: If you specify truncate something other than 0, the output will be truncated to that number of bytes. For
  /// example, if you want a SHA256 digest as the first 16 bytes, set truncate to 16.
  public func computeSHA256(truncateTo: Int = 0) throws -> Data {
    try self.withUnsafeBytes { bufferPointer in
      var byteCursor = aws_byte_cursor_from_array(bufferPointer.baseAddress, count)
      let bufferSize = Int(AWS_SHA256_LEN)
      var bufferData = Data(count: bufferSize)
      try bufferData.withUnsafeMutableBytes { bufferDataPointer in
        var buffer = aws_byte_buf_from_empty_array(bufferDataPointer.baseAddress, bufferSize)
        guard
          aws_sha256_compute(allocator.rawValue, &byteCursor, &buffer, truncateTo) == AWS_OP_SUCCESS
        else {
          throw CommonRunTimeError.crtError(.makeFromLastError())
        }
      }
      return bufferData
    }
  }

  /// Computes the sha1 hash over data.
  /// - Parameter truncateTo: If you specify truncate something other than 0, the output will be truncated to that number of bytes. For
  /// example, if you want a SHA1 digest as the first 10 bytes, set truncate to 10.
  public func computeSHA1(truncateTo: Int = 0) throws -> Data {
    try self.withUnsafeBytes { bufferPointer in
      var byteCursor = aws_byte_cursor_from_array(bufferPointer.baseAddress, count)
      let bufferSize = Int(AWS_SHA1_LEN)
      var bufferData = Data(count: bufferSize)
      try bufferData.withUnsafeMutableBytes { bufferDataPointer in
        var buffer = aws_byte_buf_from_empty_array(bufferDataPointer.baseAddress, bufferSize)
        guard
          aws_sha1_compute(allocator.rawValue, &byteCursor, &buffer, truncateTo) == AWS_OP_SUCCESS
        else {
          throw CommonRunTimeError.crtError(.makeFromLastError())
        }
      }
      return bufferData
    }
  }
}
