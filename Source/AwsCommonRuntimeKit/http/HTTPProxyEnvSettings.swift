//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp

public struct HTTPProxyEnvSettings: CStruct {
    public var envVarType: HTTPProxyEnvType
    public var proxyConnectionType: HTTPProxyConnectionType
    public var tlsOptions: TLSConnectionOptions?

    public init(envVarType: HTTPProxyEnvType = .disable,
                proxyConnectionType: HTTPProxyConnectionType = .forward,
                tlsOptions: TLSConnectionOptions? = nil) {
        self.envVarType = envVarType
        self.proxyConnectionType = proxyConnectionType
        self.tlsOptions = tlsOptions
    }

    typealias RawType = proxy_env_var_settings
    func withCStruct<Result>(_ body: (proxy_env_var_settings) -> Result) -> Result {
        var cProxyEnvSettings = proxy_env_var_settings()
        cProxyEnvSettings.env_var_type = envVarType.rawValue
        cProxyEnvSettings.connection_type = proxyConnectionType.rawValue
        return withOptionalCStructPointer(to: tlsOptions) { tlsOptionsPointer in
            cProxyEnvSettings.tls_options = tlsOptionsPointer
            return body(cProxyEnvSettings)
        }
    }
}
