//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCCommon

public struct CRTError: Error {

    public let errorCode: Int32

    public let errorMessage: String

    public let errorName: String

    public init(errorCode: Int32) {
        self.errorCode = errorCode
        self.errorMessage = String(cString: aws_error_str(errorCode))
        self.errorName = String(cString: aws_error_name(errorCode))
    }
}
