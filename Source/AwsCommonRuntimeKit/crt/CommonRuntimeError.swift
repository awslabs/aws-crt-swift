// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import AwsCCommon
import Foundation

public enum CommonRunTimeError: Error {
    case crtError(CRTError)
}

public struct CRTError: Equatable {
    public let code: Int32
    public let message: String
    public let name: String

    public init<T: BinaryInteger>(code: T, context: String? = nil) {
        if code > INT32_MAX || code <= 0 {
            self.code = Int32(AWS_ERROR_UNKNOWN.rawValue)
        } else {
            self.code = Int32(code)
        }
        var message = String(cString: aws_error_str(self.code))
        if let context {
            message += ". " + context;
        }
        self.message = message 
        self.name = String(cString: aws_error_name(self.code))
    }

    public static func makeFromLastError() -> CRTError {
        return CRTError(code: aws_last_error())
    }
}
