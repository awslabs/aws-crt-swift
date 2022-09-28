//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCCommon
import Foundation

public protocol ByteCursor {
    var rawValue: aws_byte_cursor { get set }
}

extension aws_byte_cursor: ByteCursor {
    public var rawValue: aws_byte_cursor {
        get { self }
        set(value) {
            self = value
        }
    }
}

public extension aws_byte_cursor {
    func toString() -> String? {
        if len == 0 { return nil }
        return String(bytesNoCopy: ptr, length: len, encoding: .utf8, freeWhenDone: false)
    }

    func toData() -> Data {
        Data(bytesNoCopy: ptr, count: len, deallocator: .none)
    }
}

public extension String {
    func newByteCursor() -> ByteCursor {
        StringByteCursor(self)
    }
}

private struct StringByteCursor: ByteCursor {
    private let string: ContiguousArray<CChar>
    var rawValue: aws_byte_cursor

    init(_ string: String) {
        self.string = string.utf8CString
        self.rawValue = aws_byte_cursor_from_array(
            self.string.withUnsafeBufferPointer { ptr in ptr.baseAddress },
            self.string.count - 1)
    }
}
