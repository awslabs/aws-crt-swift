//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCCommon

public struct HttpConnectionError: Error {
    
    private let errorCode: Int
    
    let errorMessage: String?
    
    public init(errorCode: Int) {
        self.errorCode = errorCode
        let stringPtr = aws_error_str(Int32(errorCode))
        if let stringPtr = stringPtr {
            self.errorMessage = String(cString: stringPtr)
        } else {
            self.errorMessage = nil
        }
    }
    
}
