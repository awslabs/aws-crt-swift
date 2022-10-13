//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCCommon

public struct AWSError {

    public let errorCode: Int32

    public let errorMessage: String?

    public init(errorCode: Int32) {
        self.errorCode = errorCode
        if let stringPtr = aws_error_str(errorCode) {
            self.errorMessage = String(cString: stringPtr)
        } else {
            self.errorMessage = nil
        }
    }

    public static func makeFromLastError() -> AWSError {
        return AWSError(errorCode: aws_last_error())
    }
}
