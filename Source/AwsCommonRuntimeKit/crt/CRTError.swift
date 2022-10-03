// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.
import AwsCCommon

extension CRTError {
    public init(fromErrorCode errorCode: Int32) {
        self = CRTError(rawValue: errorCode) ?? .UNKNOWN_ERROR_CODE
    }

    public init(fromErrorCode errorCode: Int) {
        self = CRTError(rawValue: Int32(errorCode)) ?? .UNKNOWN_ERROR_CODE
    }

    public var errorCode: Int32 {
        get {
            rawValue
        }
    }

    public var errorMessage: String {
            return String(cString: aws_error_str(rawValue))
    }

    public var errorName: String {
        return String(describing: self)
    }
}
