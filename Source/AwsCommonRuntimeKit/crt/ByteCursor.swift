//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCCommon
import Foundation

extension aws_byte_cursor {
    func toString() -> String? {
        //Todo: refactor. cursor -> aws string -> c string -> swift string is not optimal.
        // Will refactor after figuring out the encoding for authorization header.
        if self.len == 0 { return nil }
        let awsStr = withUnsafePointer(to: self) {aws_string_new_from_cursor(defaultAllocator, $0)}
        guard let cStr = aws_string_c_str(awsStr) else {
            return nil
        }
        return String(cString: cStr)
    }

    func toData() -> Data {
        return Data(bytesNoCopy: self.ptr, count: self.len, deallocator: .none)
    }
}
