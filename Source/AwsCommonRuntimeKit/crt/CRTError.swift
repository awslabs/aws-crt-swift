//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCCommon

public struct CRTError: Error {

    public let errorCode: Int32

    public let errorMessage: String?

    public let errorName: String?

    public init(errorCode: Int32) {
        self.errorCode = errorCode
        if let stringPtr = aws_error_str(errorCode) {
            self.errorMessage = String(cString: stringPtr)
        } else {
            self.errorMessage = nil
        }
        if let stringPtr = aws_error_name(errorCode) {
            self.errorName = String(cString: stringPtr)
        } else {
            self.errorName = nil
        }

    }
}
