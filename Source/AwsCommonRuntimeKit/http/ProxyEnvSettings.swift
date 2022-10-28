//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp

public class ProxyEnvSettings: CStruct {
    public var envVarType: HttpProxyEnvType
    public var proxyConnectionType: HttpProxyConnectionType
    public var tlsOptions: TlsConnectionOptions?

    public init(envVarType: HttpProxyEnvType = .disable,
                proxyConnectionType: HttpProxyConnectionType = .forward,
                tlsOptions: TlsConnectionOptions? = nil) {
        self.envVarType = envVarType
        self.proxyConnectionType = proxyConnectionType
        self.tlsOptions = tlsOptions
    }

    typealias RawType = proxy_env_var_settings
    func withCStruct<Result>(_ body: (proxy_env_var_settings) -> Result) -> Result {
        var cProxyEnvSettings = proxy_env_var_settings()
        cProxyEnvSettings.env_var_type = envVarType.rawValue
        cProxyEnvSettings.connection_type = proxyConnectionType.rawValue
        cProxyEnvSettings.tls_options = UnsafePointer(tlsOptions?.rawValue)

        return body(cProxyEnvSettings)
    }
}
