//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCCommon
import Foundation

public protocol ByteCursor {
    var rawValue: aws_byte_cursor { get set }
}

extension aws_byte_cursor: ByteCursor {
    public var rawValue: aws_byte_cursor {
        get { return self }
        set(value) {
            self = value
        }
    }
}

extension aws_byte_cursor {
    public func toString() -> String? {
        if self.len == 0 { return nil }
        return String(bytesNoCopy: self.ptr, length: self.len, encoding: .utf8, freeWhenDone: false)
    }

    public func toData() -> Data {
        return Data(bytesNoCopy: self.ptr, count: self.len, deallocator: .none)
    }
}

extension String {
    public func newByteCursor() -> ByteCursor {
        return StringByteCursor(self)
    }
}

private struct StringByteCursor: ByteCursor {
    private let string: ContiguousArray<CChar>
    var rawValue: aws_byte_cursor

    init(_ string: String) {
        self.string = string.utf8CString
        self.rawValue = aws_byte_cursor_from_array(
            self.string.withUnsafeBufferPointer { ptr in return ptr.baseAddress },
            self.string.count - 1
        )
    }
}
