//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCCommon

final class AWSString {
    let string: String
    let rawValue: UnsafeMutablePointer<aws_string>

    init(_ str: String, allocator: Allocator) {
        string = str
        rawValue = aws_string_new_from_array(allocator.rawValue, str, str.count)
    }

    var count: Int {
        rawValue.pointee.len
    }

    func newByteCursor() -> ByteCursor {
        AWSStringByteCursor(self)
    }

    func asCStr() -> UnsafePointer<Int8> {
        aws_string_c_str(rawValue)
    }

    deinit {
        aws_string_destroy(self.rawValue)
    }
}

private struct AWSStringByteCursor: ByteCursor {
    private let awsString: AWSString
    public var rawValue: aws_byte_cursor

    init(_ awsString: AWSString) {
        self.awsString = awsString
        rawValue = aws_byte_cursor_from_string(awsString.rawValue)
    }
}

public extension String {
    internal init?(awsString: UnsafePointer<aws_string>, encoding: String.Encoding = .utf8) {
        self.init(cString: aws_string_c_str(awsString), encoding: encoding)
    }

    func asCStr() -> UnsafePointer<Int8>? {
        aws_string_c_str(aws_string_new_from_array(defaultAllocator, self, count))
    }

    func toInt32() -> Int32 {
        Int32(bitPattern: UnicodeScalar(self)?.value ?? 0)
    }
}
