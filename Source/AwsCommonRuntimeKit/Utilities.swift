//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCIo
import Foundation

@inlinable
internal func readBinaryFile(_ path: String) throws -> Data {
  guard let handle = FileHandle(forReadingAtPath: path) else {
    throw AwsError.fileNotFound(path)
  }
  return handle.readDataToEndOfFile()
}

@inlinable
internal func zeroStruct<T>(_ ptr: UnsafeMutablePointer<T>) {
  memset(ptr, 0x00, MemoryLayout<T>.size)
}

internal extension Data {
  @inlinable
  var awsByteCursor: aws_byte_cursor {
    return withUnsafeBytes { (rawPtr: UnsafeRawBufferPointer) -> aws_byte_cursor in
      return aws_byte_cursor_from_array(rawPtr.baseAddress, self.count)
    }
  }
}

internal extension String {
  @inlinable
  var awsByteCursor: aws_byte_cursor {
    return aws_byte_cursor_from_c_str(self)
  }
}

public extension Int32 {
    func toString() -> String? {
        let u = UnicodeScalar(Int(self))
        // Convert UnicodeScalar to a String.
        if let u = u {
            return String(u)
        }
        return nil
    }
}
