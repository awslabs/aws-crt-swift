//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCCommon
import Foundation

extension aws_byte_cursor {
    // Todo: how to deallocate the cursor?
    func toString() -> String? {
        if self.len == 0 { return nil }
        let data = Data(bytesNoCopy: self.ptr, count: self.len, deallocator: .none)
        return String(data: data, encoding: .utf8)
    }
}
