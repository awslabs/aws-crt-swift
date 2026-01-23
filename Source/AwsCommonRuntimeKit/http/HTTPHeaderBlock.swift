//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp

enum HTTPHeaderBlock {
  /// Main header block sent with request or response.
  case main
  /// Header block for 1xx informational (interim) responses.
  case informational
  /// Headers sent after the body of a request or response.
  case trailing
  /// Unknwon HTTPHeaderBlock field
  case sdkUnknown(Swift.String)
}

extension HTTPHeaderBlock {

  init(rawValue: aws_http_header_block) {
    switch rawValue {
    case AWS_HTTP_HEADER_BLOCK_MAIN:
      self = .main
    case AWS_HTTP_HEADER_BLOCK_INFORMATIONAL:
      self = .informational
    case AWS_HTTP_HEADER_BLOCK_TRAILING:
      self = .trailing
    default:
      self = .sdkUnknown("\(rawValue)")
    }
  }

  var rawValue: aws_http_header_block {
    switch self {
    case .main: return AWS_HTTP_HEADER_BLOCK_MAIN
    case .informational: return AWS_HTTP_HEADER_BLOCK_INFORMATIONAL
    case .trailing: return AWS_HTTP_HEADER_BLOCK_TRAILING
    case let .sdkUnknown(s): fatalError("Unknown HTTPHeaderBlock Type: \(s)")
    }
  }
}
