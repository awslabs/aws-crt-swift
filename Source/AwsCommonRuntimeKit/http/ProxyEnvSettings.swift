//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp

public class ProxyEnvSettings {
    private let rawValue: UnsafeMutablePointer<proxy_env_var_settings>
    let allocator: Allocator

    public var envVarType: HttpProxyEnvType
    public var proxyConnectionType: HttpProxyConnectionType
    public var tlsOptions: TlsConnectionOptions?

    public init(envVarType: HttpProxyEnvType = .disable,
                proxyConnectionType: HttpProxyConnectionType = .forward,
                tlsOptions: TlsConnectionOptions? = nil,
                allocator: Allocator = defaultAllocator) {

        self.allocator = allocator
        self.envVarType = envVarType
        self.proxyConnectionType = proxyConnectionType
        self.tlsOptions = tlsOptions
        self.rawValue = allocator.allocate(capacity: 1)
    }

    func getRawValue() -> UnsafeMutablePointer<proxy_env_var_settings> {
        rawValue.pointee.env_var_type = envVarType.rawValue
        rawValue.pointee.connection_type = proxyConnectionType.rawValue
        rawValue.pointee.tls_options = UnsafePointer(tlsOptions?.rawValue)

        return rawValue
    }

    deinit {
        allocator.release(rawValue)
    }
}
