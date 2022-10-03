//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

/// Error type for all errors thrown by the Swift code including C runtime errors
public enum AWSCommonRuntimeError: Error {

    /// Use aws_last_error() as the error code if no value is provided
    case AWSCRTError(_ crtError: CRTError = CRTError())
}
