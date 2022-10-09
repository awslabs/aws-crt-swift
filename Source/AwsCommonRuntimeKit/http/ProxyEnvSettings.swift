//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp

public class ProxyEnvSettings {
    let rawValue: UnsafeMutablePointer<proxy_env_var_settings>
    let allocator: Allocator

    public var envVarType: HttpProxyEnvType {
        didSet {
            rawValue.pointee.env_var_type = envVarType.rawValue;
        }
    }
    public var proxyConnectionType: HttpProxyConnectionType {
        didSet {
            rawValue.pointee.connection_type = proxyConnectionType.rawValue
        }
    }
    public var tlsOptions: TlsConnectionOptions? {
        didSet {
            rawValue.pointee.tls_options = UnsafePointer(tlsOptions?.rawValue)
        }
    }


    public init(envVarType: HttpProxyEnvType = .disable,
                proxyConnectionType: HttpProxyConnectionType = .forward,
                tlsOptions: TlsConnectionOptions? = nil,
                allocator: Allocator = defaultAllocator) {

        self.allocator = allocator
        self.rawValue = allocator.allocate(capacity: 1)
        self.envVarType = envVarType
        self.proxyConnectionType = proxyConnectionType
        self.tlsOptions = tlsOptions

        //Set these values for rawValue as well because didSet is not triggered in init
        rawValue.pointee.env_var_type = envVarType.rawValue
        rawValue.pointee.connection_type = proxyConnectionType.rawValue
        rawValue.pointee.tls_options = UnsafePointer(tlsOptions?.rawValue)
    }

    deinit {
        allocator.release(rawValue)
    }
}
