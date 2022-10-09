//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCCommon

public struct CRTError: Error {

    public let code: Int32

    public let message: String

    public let name: String

    public init(errorCode: Int32) {
        self.code = errorCode
        self.message = String(cString: aws_error_str(errorCode))
        self.name = String(cString: aws_error_name(errorCode))
    }


    public static func makeFromLastError() -> CRTError{
        return CRTError(errorCode: aws_last_error())
    }

}
