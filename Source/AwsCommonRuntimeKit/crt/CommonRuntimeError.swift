// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import AwsCCommon
import Foundation

public enum CommonRunTimeError: Error {
    case crtError(CRTError)
}

public struct CRTError {
    public let code: Int32
    public let message: String
    public let name: String

    public init<T: BinaryInteger>(code: T) {
        if code > INT32_MAX || code < 0 {
            self.code = AWS_OP_ERR // Error Unknown
        } else {
            self.code = Int32(code)
        }
        self.message = String(cString: aws_error_str(self.code))
        self.name = String(cString: aws_error_name(self.code))
    }

    public static func makeFromLastError() -> CRTError {
        return CRTError(code: aws_last_error())
    }
}
