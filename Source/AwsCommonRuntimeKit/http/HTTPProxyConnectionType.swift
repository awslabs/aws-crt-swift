//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp

public enum HTTPProxyConnectionType {
  /// Deprecated, but 0-valued for backwards compatibility
  /// If tls options are provided (for the main connection) then treat the proxy as a tunneling proxy
  /// If tls options are not provided (for the main connection), then treat the proxy as a forwarding proxy
  case legacy
  /// Use the proxy to forward http requests.  Attempting to use both this mode and TLS on the tunnel destination
  /// is a configuration error.
  case forward
  /// Use the proxy to establish a connection to a remote endpoint via a CONNECT request through the proxy.
  /// Works for both plaintext and tls connections.
  case tunnel
}

extension HTTPProxyConnectionType {
  var rawValue: aws_http_proxy_connection_type {
    switch self {
    case .legacy: return AWS_HPCT_HTTP_LEGACY
    case .forward: return AWS_HPCT_HTTP_FORWARD
    case .tunnel: return AWS_HPCT_HTTP_TUNNEL
    }
  }
}
