//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

public enum SocketDomain {
  case ipv4
  case ipv6
  case local
}

extension SocketDomain {
  var rawValue: aws_socket_domain {
    switch self {
    case .ipv4: return aws_socket_domain(rawValue: 0)
    case .ipv6: return aws_socket_domain(rawValue: 1)
    case .local: return aws_socket_domain(rawValue: 2)
    }
  }
}
