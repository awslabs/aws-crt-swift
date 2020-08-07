//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCIo
import struct Foundation.Date
import struct Foundation.Data
import class Foundation.FileHandle
import AwsCCommon

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
        let pointer = UnsafeMutablePointer<aws_date_time>.allocate(capacity: 1)

        aws_date_time_init_epoch_millis(pointer, datefrom1970)
        return pointer.pointee
    }
}

extension Bool {
    var uintValue: UInt32 {
        return self ? 1 : 0
    }
}
