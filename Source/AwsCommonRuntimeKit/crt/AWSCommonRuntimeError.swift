//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCCommon

public struct AWSCommonRuntimeError: Error {
  private let code = aws_last_error()

  internal init() {}
}
