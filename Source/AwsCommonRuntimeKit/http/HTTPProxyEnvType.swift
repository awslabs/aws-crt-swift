//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp

public enum HTTPProxyEnvType {
    /// Default. Disable reading from environment variable for proxy.
    case disable
    /// Enable get proxy URL from environment variable, when the manual proxy options of connection manager is not set.
    /// env HTTPS_PROXY/https_proxy will be checked when the main connection use tls.
    /// env HTTP_PROXY/http_proxy will be checked when the main connection NOT use tls.
    /// The lower case version has precedence.
    case enable
}

extension HTTPProxyEnvType {
    var rawValue: aws_http_proxy_env_var_type {
        switch self {
        case .disable:  return AWS_HPEV_DISABLE
        case .enable: return AWS_HPEV_ENABLE
        }
    }
}
