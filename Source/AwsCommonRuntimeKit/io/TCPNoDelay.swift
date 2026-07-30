//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

/// Controls the TCP_NODELAY socket option (whether Nagle's algorithm is disabled).
/// TCP only. Ignored for UDP and AWS_SOCKET_LOCAL sockets.
public enum TCPNoDelay {
  /// Leave the OS default in place (Nagle's algorithm enabled on most platforms).
  case osDefault
  /// Set TCP_NODELAY on, disabling Nagle's algorithm so small writes are sent immediately.
  case on
  /// Set TCP_NODELAY off, explicitly (re)enabling Nagle's algorithm.
  case off
}

extension TCPNoDelay {
  var rawValue: aws_socket_tcp_nodelay {
    switch self {
    case .osDefault: return AWS_SOCKET_TCP_NODELAY_DEFAULT
    case .on: return AWS_SOCKET_TCP_NODELAY_ON
    case .off: return AWS_SOCKET_TCP_NODELAY_OFF
    }
  }
}
