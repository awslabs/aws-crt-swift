//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCCommon
import Foundation

extension aws_byte_cursor {
    public func toString() -> String? {
        if self.len == 0 { return nil }
        return String(bytes: UnsafeBufferPointer(start: self.ptr, count: self.len), encoding: .utf8)
    }
}
