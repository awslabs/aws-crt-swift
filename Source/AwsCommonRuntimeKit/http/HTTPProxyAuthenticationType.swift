//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp

public enum HTTPProxyAuthenticationType {
  /// No authentication
  case none
  /// Basic (username and password base64 encoded) authentication
  case basic
}

extension HTTPProxyAuthenticationType {
  var rawValue: aws_http_proxy_authentication_type {
    switch self {
    case .none: return AWS_HPAT_NONE
    case .basic: return AWS_HPAT_BASIC
    }
  }
}
