//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCCommon

public enum CrtError: Error {
  case fileNotFound(String)
  case memoryAllocationFailure
  case stringConversionError(UnsafePointer<aws_string>?)
  case crtError(AwsError)
}


public struct AwsError {
    let errorMessage: String
    
    public init(errorCode: Int32) {
        let cString = aws_error_str(errorCode)
        errorMessage = String(cString: cString!)
    }
}
