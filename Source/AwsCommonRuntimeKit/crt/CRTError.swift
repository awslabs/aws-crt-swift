//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import Foundation
import AwsCCommon

public enum CRTError: Error {
  case fileNotFound(String)
  case memoryAllocationFailure
  case stringConversionError(UnsafePointer<aws_string>?)
  case crtError(AWSError)
}
