//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCCommon

internal final class AwsString {
  internal let string: String
  internal let rawValue: UnsafeMutablePointer<aws_string>

  internal init(_ str: String, allocator: Allocator) {
    self.string = str
    self.rawValue = aws_string_new_from_array(allocator.rawValue, str, str.count)
  }

  internal var count: Int {
    return self.rawValue.pointee.len
  }

  internal func newByteCursor() -> ByteCursor {
    return AwsStringByteCursor(self)
  }

  internal func asCStr() -> UnsafePointer<Int8> {
    return aws_string_c_str(self.rawValue)
  }

  deinit {
    aws_string_destroy(self.rawValue)
  }
}

private struct AwsStringByteCursor: ByteCursor {
  private let awsString: AwsString
  public var rawValue: aws_byte_cursor

  fileprivate init(_ awsString: AwsString) {
    self.awsString = awsString
    self.rawValue = aws_byte_cursor_from_string(awsString.rawValue)
  }
}

extension String {
  init?(awsString: UnsafePointer<aws_string>, encoding: String.Encoding = .utf8) {
    self.init(cString: aws_string_c_str(awsString), encoding: encoding)
  }

    public func asCStr() -> UnsafePointer<Int8>? {
        return aws_string_c_str(aws_string_new_from_array(defaultAllocator, self, self.count))
    }

    public func toInt32() -> Int32 {
        return Int32(bitPattern: UnicodeScalar(self)?.value ?? 0)
    }
}
