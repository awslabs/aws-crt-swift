//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import struct Foundation.Date
import struct Foundation.Data
import struct Foundation.TimeInterval
import AwsCCal

extension Data {
    
    /// Computes the base64 encoded md5 hash over data. Use this if you don't need to stream the data you're hashing and you can load
    /// the entire input to hash into memory.
    /// - Parameter truncate: If you specify truncate something other than 0, the output will be truncated to that number of bytes.
    public func computeMD5(truncate: Int = 0) throws -> Data {
        try self.withUnsafeBytes { bufferPointer in
            var byteCursor = aws_byte_cursor_from_array(bufferPointer.baseAddress, count)

            let bufferSize = 16
            var bufferData = Data(count: bufferSize)
            try bufferData.withUnsafeMutableBytes { bufferPointer in
                var buffer = aws_byte_buf_from_empty_array(bufferPointer.baseAddress, bufferSize)
                guard aws_md5_compute(allocator.rawValue, &byteCursor, &buffer, truncate) == AWS_OP_SUCCESS else {
                    throw CommonRunTimeError.crtError(.makeFromLastError())
                }
            }
            return bufferData
        }
    }
    
    /// Computes the sha256 hash over data.
    /// - Parameter truncate: If you specify truncate something other than 0, the output will be truncated to that number of bytes. For
    /// example, if you want a SHA256 digest as the first 16 bytes, set truncate to 16.
    public func computeSHA256(truncate: Int = 0) throws -> Data {
        try self.withUnsafeBytes { bufferPointer in
            var byteCursor = aws_byte_cursor_from_array(bufferPointer.baseAddress, count)
            let bufferSize = Int(AWS_SHA256_LEN)
            var bufferData = Data(count: bufferSize)
            try bufferData.withUnsafeMutableBytes { bufferDataPointer in
                var buffer = aws_byte_buf_from_empty_array(bufferDataPointer.baseAddress, bufferSize)
                guard aws_sha256_compute(allocator.rawValue, &byteCursor, &buffer, truncate) == AWS_OP_SUCCESS else {
                    throw CommonRunTimeError.crtError(.makeFromLastError())
                }
            }
            return bufferData
        }
    }
    
    /// Computes the sha1 hash over data.
    /// - Parameter truncate: If you specify truncate something other than 0, the output will be truncated to that number of bytes. For
    /// example, if you want a SHA1 digest as the first 10 bytes, set truncate to 10.
    public func compteSHA1(truncate: Int = 0) throws -> Data {
        try self.withUnsafeBytes { bufferPointer in
            var byteCursor = aws_byte_cursor_from_array(bufferPointer.baseAddress, count)
            let bufferSize = Int(AWS_SHA1_LEN)
            var bufferData = Data(count: bufferSize)
            try bufferData.withUnsafeMutableBytes { bufferDataPointer in
                var buffer = aws_byte_buf_from_empty_array(bufferDataPointer.baseAddress, bufferSize)
                guard aws_sha1_compute(allocator.rawValue, &byteCursor, &buffer, truncate) == AWS_OP_SUCCESS else {
                    throw CommonRunTimeError.crtError(.makeFromLastError())
                }
            }
            return bufferData
        }
    }
}
