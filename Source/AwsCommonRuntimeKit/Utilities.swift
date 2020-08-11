//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCIo
import struct Foundation.Date
import struct Foundation.Data
import class Foundation.FileHandle
import AwsCCommon

@inlinable
func zeroStruct<T>(_ ptr: UnsafeMutablePointer<T>) {
  memset(ptr, 0x00, MemoryLayout<T>.size)
}

extension Data {
  @inlinable
  var awsByteCursor: aws_byte_cursor {
    return withUnsafeBytes { (rawPtr: UnsafeRawBufferPointer) -> aws_byte_cursor in
      return aws_byte_cursor_from_array(rawPtr.baseAddress, self.count)
    }
  }
}

extension String {
  @inlinable
  var awsByteCursor: aws_byte_cursor {
    return aws_byte_cursor_from_c_str(self.asCStr())
  }
}

public extension Int32 {
    func toString() -> String? {
        // Convert UnicodeScalar to a String.
        if let unicodeScalar = UnicodeScalar(Int(self)) {
            return String(unicodeScalar)
        }
        return nil
    }
}

extension UnsafeMutablePointer {
    func deinitializeAndDeallocate() {
        self.deinitialize(count: 1)
        self.deallocate()
    }
}

extension Date {
    var awsDateTime: aws_date_time {
        let datefrom1970 = UInt64(self.timeIntervalSince1970 * 1000)
        let dateTime = AWSDate(epochMs: datefrom1970)
        return dateTime.rawValue.pointee
    }
}

extension Bool {
    var uintValue: UInt32 {
        return self ? 1 : 0
    }
}
