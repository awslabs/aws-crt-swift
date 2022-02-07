//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp

public class ProxyEnvSettings {
    let rawValue: UnsafeMutablePointer<proxy_env_var_settings>
    public var envVarType: HttpProxyEnvType = .disable
    public var proxyConnectionType: HttpProxyConnectionType = .forward
    public var tlsOptions: TlsConnectionOptions?

    public init(envVarType: HttpProxyEnvType = .disable,
                proxyConnectionType: HttpProxyConnectionType = .forward,
                tlsOptions: TlsConnectionOptions? = nil) {
        self.rawValue = allocatePointer()
        self.envVarType = envVarType
        self.proxyConnectionType = proxyConnectionType
        self.tlsOptions = tlsOptions
    }

    deinit {
        rawValue.deinitializeAndDeallocate()
    }
}
