//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth
import AwsCIo
import AwsCHttp

class AWSCredentialsProvider: CredentialsProvider {
    public var allocator: Allocator
    public var rawValue: UnsafeMutablePointer<aws_credentials_provider>
    
    required public init(connection: UnsafeMutablePointer<aws_credentials_provider>,
                         allocator: Allocator = defaultAllocator) {
        self.allocator = allocator
        self.rawValue = connection
    }
    
    convenience init?(fromStatic config: CredentialsProviderStaticConfigOptions,
                      allocator: Allocator = defaultAllocator) {
        guard let provider = aws_credentials_provider_new_static(allocator.rawValue,
                                                                 config.rawValue) else {
                                                                    return nil
        }
        self.init(connection: provider, allocator: allocator)
    }
    
    convenience init?(fromEnv shutdownOptions: CredentialsProviderShutdownOptions?,
                      allocator: Allocator = defaultAllocator) {
        let options = UnsafeMutablePointer<aws_credentials_provider_environment_options>.allocate(capacity: 1)

        var envOptions = aws_credentials_provider_environment_options()
        envOptions.shutdown_options = AWSCredentialsProvider.setUpShutDownOptions(shutDownOptions: shutdownOptions)

        options.initialize(to: envOptions)
        guard let provider = aws_credentials_provider_new_environment(allocator.rawValue,
                                                                      options) else {return nil}
        defer { options.deinitializeAndDeallocate()}
        self.init(connection: provider, allocator: allocator)
    }
    
    convenience init?(fromProfile profileOptions: CredentialsProviderProfileOptions,
                      allocator: Allocator = defaultAllocator) {
        let options = UnsafeMutablePointer<aws_credentials_provider_profile_options>.allocate(capacity: 1)
       
        
        var profileOptionsC = aws_credentials_provider_profile_options()
        profileOptionsC.config_file_name_override = profileOptions.configFileNameOverride.awsByteCursor
        profileOptionsC.credentials_file_name_override = profileOptions.credentialsFileNameOverride.awsByteCursor
        profileOptionsC.profile_name_override = profileOptions.profileFileNameOverride.awsByteCursor
        profileOptionsC.shutdown_options = AWSCredentialsProvider.setUpShutDownOptions(shutDownOptions: profileOptions.shutdownOptions)

        options.initialize(to: profileOptionsC)
        guard let provider = aws_credentials_provider_new_profile(allocator.rawValue,
                                                                  options) else {
            return nil
                                                                    
        }
        defer {
            options.deinitializeAndDeallocate()
        }
        self.init(connection: provider, allocator: allocator)
    }
    
    convenience init?(fromImds imdsConfig: CredentialsProviderImdsConfig,
                      allocator: Allocator = defaultAllocator) {
        let options = UnsafeMutablePointer<aws_credentials_provider_imds_options>.allocate(capacity: 1)
        let shutDownOptions = AWSCredentialsProvider.setUpShutDownOptions(shutDownOptions: imdsConfig.shutdownOptions)
        let imdsOptions = aws_credentials_provider_imds_options(shutdown_options: shutDownOptions,
                                                                bootstrap: imdsConfig.bootstrap.rawValue,
                                                                imds_version: imdsConfig.imdsVersion,
                                                                function_table: nil)
        options.initialize(to: imdsOptions)
        guard let provider = aws_credentials_provider_new_imds(allocator.rawValue, options) else {return nil}
        
        defer {
            options.deinitializeAndDeallocate()
        }
        self.init(connection: provider, allocator: allocator)
    }
    
    convenience init?(fromChain chainConfig: CredentialsProviderChainConfig,
                      allocator: Allocator = defaultAllocator) {
        var vectorBuf : UnsafeMutablePointer<aws_credentials_provider>?
        vectorBuf = UnsafeMutablePointer<aws_credentials_provider>.allocate(capacity: chainConfig.providers.count)
        for index in 0...chainConfig.providers.count {
            vectorBuf!.advanced(by: index).initialize(to: chainConfig.providers[index].rawValue.pointee)
        }
        
        let providers = UnsafeMutablePointer<UnsafeMutablePointer<aws_credentials_provider>?>.allocate(capacity: 1)
        providers.initialize(to: vectorBuf)
        defer{
            vectorBuf?.deinitializeAndDeallocate()
            providers.deinitializeAndDeallocate()
        }
        let options = UnsafeMutablePointer<aws_credentials_provider_chain_options>.allocate(capacity: 1)
        let shutDownOptions = AWSCredentialsProvider.setUpShutDownOptions(shutDownOptions: chainConfig.shutDownOptions)
        let chainOptions = aws_credentials_provider_chain_options(shutdown_options: shutDownOptions,
                                                                  providers:providers,
                                                                  provider_count: chainConfig.providers.count)
        options.initialize(to: chainOptions)
        defer { options.deinitializeAndDeallocate() }
        guard let provider = aws_credentials_provider_new_chain(allocator.rawValue,
                                                                nil) else {return nil}
        self.init(connection: provider, allocator: allocator)
    }
    
    convenience init?(fromCached cachedConfig: CredentialsProviderCachedConfig,
                      allocator: Allocator = defaultAllocator) {
        let cachedOptionsPointer = UnsafeMutablePointer<aws_credentials_provider_cached_options>.allocate(capacity: 1)
        let shutDownOptions = AWSCredentialsProvider.setUpShutDownOptions(shutDownOptions: cachedConfig.shutDownOptions)
        let cachedOptions = aws_credentials_provider_cached_options(shutdown_options: shutDownOptions,
                                                                    source: cachedConfig.source.rawValue,
                                                                    refresh_time_in_milliseconds: UInt64(cachedConfig.refreshTimeMs),
                                                                    high_res_clock_fn: nil,
                                                                    system_clock_fn: nil)
        cachedOptionsPointer.initialize(to: cachedOptions)
        defer { cachedOptionsPointer.deinitializeAndDeallocate() }
        
        guard let provider = aws_credentials_provider_new_cached(allocator.rawValue, cachedOptionsPointer) else {
            return nil
        }
        self.init(connection: provider, allocator: allocator)
    }
    
    convenience init?(fromChainDefault chainDefaultConfig: CredentialsProviderChainDefaultConfig, allocator: Allocator = defaultAllocator) {
        let chainDefaultOptionsPtr = UnsafeMutablePointer<aws_credentials_provider_chain_default_options>.allocate(capacity: 1)
        let shutDownOptions = AWSCredentialsProvider.setUpShutDownOptions(shutDownOptions: chainDefaultConfig.shutDownOptions)
        let chainDefaultOptions = aws_credentials_provider_chain_default_options(shutdown_options: shutDownOptions,
                                                                                 bootstrap: chainDefaultConfig.bootstrap.rawValue)
        chainDefaultOptionsPtr.initialize(to: chainDefaultOptions)
        defer { chainDefaultOptionsPtr.deinitializeAndDeallocate() }
        guard let provider = aws_credentials_provider_new_chain_default(allocator.rawValue, chainDefaultOptionsPtr) else {
            return nil
        }
        self.init(connection: provider, allocator: allocator)
    }
    
    convenience init?(fromx509 x509Config: CredentialsProviderX509Config,
                      allocator: Allocator = defaultAllocator) {
        let tlsOptionsPtr = UnsafeMutablePointer<aws_tls_connection_options>.allocate(capacity: 1)
        tlsOptionsPtr.initialize(to: x509Config.tlsConnectionOptions.rawValue)
        let proxyOptionsPtr = UnsafeMutablePointer<aws_http_proxy_options>.allocate(capacity: 1)
        proxyOptionsPtr.initialize(to: x509Config.proxyOptions.rawValue)
        let x509OptionsPtr = UnsafeMutablePointer<aws_credentials_provider_x509_options>.allocate(capacity: 1)
        let shutDownOptions = AWSCredentialsProvider.setUpShutDownOptions(shutDownOptions: x509Config.shutDownOptions)
        let x509Options = aws_credentials_provider_x509_options(shutdown_options: shutDownOptions,
                                                                bootstrap: x509Config.bootstrap.rawValue,
                                                                tls_connection_options: UnsafePointer(tlsOptionsPtr),
                                                                thing_name: x509Config.thingName.awsByteCursor,
                                                                role_alias: x509Config.roleAlias.awsByteCursor,
                                                                endpoint: x509Config.endpoint.awsByteCursor,
                                                                proxy_options: UnsafePointer(proxyOptionsPtr),
                                                                function_table: nil)
        x509OptionsPtr.initialize(to: x509Options)
        
        defer {
            tlsOptionsPtr.deinitializeAndDeallocate()
            proxyOptionsPtr.deinitializeAndDeallocate()
            x509OptionsPtr.deinitializeAndDeallocate()
        }
        
        guard let provider = aws_credentials_provider_new_x509(allocator.rawValue, x509OptionsPtr) else {
            return nil
        }
        self.init(connection: provider, allocator: allocator)
    }
    
    func getCredentials(credentialCallBackData: CredentialProviderCallbackData) {
        let data = Unmanaged.passRetained(credentialCallBackData).toOpaque()
        aws_credentials_provider_get_credentials(rawValue, { (credentials, errorCode, userdata) -> Void in
            guard let userdata = userdata else {
                return
            }
            let callback: CredentialProviderCallbackData = Unmanaged.fromOpaque(userdata).takeRetainedValue()
           
            callback.onCredentialsResolved(Credentials(rawValue: credentials), errorCode)

        }, data)
        
    }
    
    static func setUpShutDownOptions(shutDownOptions: CredentialsProviderShutdownOptions?) -> aws_credentials_provider_shutdown_options {
        let shutDownOptionsC: aws_credentials_provider_shutdown_options?
        if let shutDownOptions = shutDownOptions {
            let shutDownOptionsData = Unmanaged.passRetained(shutDownOptions).toOpaque()
            shutDownOptionsC = aws_credentials_provider_shutdown_options(shutdown_callback: { userData in
                guard let userData = userData else {
                    return
                }
                
                let shutDownOptions: CredentialsProviderShutdownOptions = Unmanaged.fromOpaque(userData).takeRetainedValue()

                shutDownOptions.shutDownCallback()
                
            }, shutdown_user_data: shutDownOptionsData)
        } else {
            shutDownOptionsC = aws_credentials_provider_shutdown_options()
        }
        return shutDownOptionsC!
    }
    
    deinit {
        aws_credentials_provider_release(rawValue)
    }
}
