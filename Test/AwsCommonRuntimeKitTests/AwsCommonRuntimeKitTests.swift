//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
@testable
import AwsCommonRuntimeKit
import Foundation

let range = NSRange(location: 0, length: AwsCommonRuntimeKit.version.utf16.count)
let regex = try! NSRegularExpression(pattern: "\\Av\\d+\\.\\d+\\.\\d+\\z")

if (regex.firstMatch(in: AwsCommonRuntimeKit.version, options: [], range: range) == nil) {
  print("\(AwsCommonRuntimeKit.version) is not a valid version specifier")
  exit(-1)
}
