// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import AwsCCommon

public enum CommonRunTimeError: Error {
    case crtError(CRTError)
}

public struct CRTError {

    public let code: Int32

    public let message: String

    public let name: String

    public init(code: Int32) {
        self.code = code
        self.message = String(cString: aws_error_str(code))
        self.name = String(cString: aws_error_name(code))
    }

    public static func makeFromLastError() -> CRTError {
        return CRTError(code: aws_last_error())
    }
}
