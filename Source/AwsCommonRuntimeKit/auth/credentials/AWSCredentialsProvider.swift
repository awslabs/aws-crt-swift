//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth
import AwsCIo
import AwsCHttp

//open cuz can be subclassed with credentials provider to implement for runtime specific usage.
open class AWSCredentialsProvider: CredentialsProvider {
    public var allocator: Allocator
    public var rawValue: UnsafeMutablePointer<aws_credentials_provider>

    required public init(connection: UnsafeMutablePointer<aws_credentials_provider>,
                         allocator: Allocator = defaultAllocator) {
        self.allocator = allocator
        self.rawValue = connection
    }

    func getCredentials(credentialCallBackData: CredentialProviderCallbackData) {
        let data = UnsafeMutablePointer<CredentialProviderCallbackData>.allocate(capacity: 1)
        data.initialize(to: credentialCallBackData)
        data.pointee = credentialCallBackData
        defer {
            data.deinitializeAndDeallocate()
        }
        aws_credentials_provider_get_credentials(rawValue, { (credentials, errorCode, userdata) -> Void in
            guard let userdata = userdata, let credentials = credentials else {
                return
            }
            
            let callback = userdata.bindMemory(to: CredentialProviderCallbackData.self, capacity: 1)
            callback.pointee.onCredentialsResolved(Credentials(rawValue: credentials), errorCode)

        }, data)
    }

    func createWrappedProvider(cProvider: UnsafeMutablePointer<aws_credentials_provider>,
                               allocator: Allocator) -> CredentialsProvider {
        let provider = AWSCredentialsProvider(connection: cProvider, allocator: allocator)
        return provider as CredentialsProvider
    }

    func createCredentialsProviderStatic(config: CredentialsProviderStaticConfigOptions) -> CredentialsProvider? {

        guard let provider = aws_credentials_provider_new_static(allocator.rawValue,
                                                                 config.rawValue) else { return nil }

        return createWrappedProvider(cProvider: provider, allocator: allocator)
    }

    func createCredentialsProviderEnvironment(shutdownOptions: CredentialsProviderShutdownOptions)
        -> CredentialsProvider? {
        let options = UnsafeMutablePointer<aws_credentials_provider_environment_options>.allocate(capacity: 1)
        let envOptions = aws_credentials_provider_environment_options(shutdown_options: shutdownOptions.rawValue.pointee)
        options.initialize(to: envOptions)
        guard let provider = aws_credentials_provider_new_environment(allocator.rawValue,
                                                                      options) else {return nil}
        defer {
            options.deinitializeAndDeallocate()
        }
        return createWrappedProvider(cProvider: provider, allocator: allocator)
    }

    func createCredentialsProviderProfile(profileOptions: CredentialsProviderProfileOptions)
        -> CredentialsProvider? {
        let options = UnsafeMutablePointer<aws_credentials_provider_profile_options>.allocate(capacity: 1)
        let profileOptions = aws_credentials_provider_profile_options(shutdown_options: profileOptions.shutdownOptions.rawValue.pointee,
                                               profile_name_override: profileOptions.profileFileNameOverride.awsByteCursor,
                                               config_file_name_override: profileOptions.configFileNameOverride.awsByteCursor,
                                               credentials_file_name_override: profileOptions.credentialsFileNameOverride.awsByteCursor,
                                               bootstrap: nil,
                                               function_table: nil)
        options.initialize(to: profileOptions)
        guard let provider = aws_credentials_provider_new_profile(allocator.rawValue,
                                                                  options) else {return nil}
        defer {
            options.deinitializeAndDeallocate()
        }
        return createWrappedProvider(cProvider: provider, allocator: allocator)
    }

    func createCredentialsProviderImds(imdsConfig: CredentialsProviderImdsConfig) -> CredentialsProvider? {
        let options = UnsafeMutablePointer<aws_credentials_provider_imds_options>.allocate(capacity: 1)

        let imdsOptions = aws_credentials_provider_imds_options(shutdown_options: imdsConfig.shutdownOptions.rawValue.pointee,
                                                                bootstrap: imdsConfig.bootstrap.rawValue,
                                                                imds_version: imdsConfig.imdsVersion, 
                                                                function_table: nil)
        options.initialize(to: imdsOptions)
        guard let provider = aws_credentials_provider_new_imds(allocator.rawValue, options) else {return nil}
        
        defer {
            options.deinitializeAndDeallocate()
        }

        return createWrappedProvider(cProvider: provider, allocator: allocator)
    }

    func createCredentialsProviderChain(chainConfig: CredentialsProviderChainConfig) -> CredentialsProvider? {
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
        
        let chainOptions = aws_credentials_provider_chain_options(shutdown_options: chainConfig.shutDownOptions.rawValue.pointee,
                                                                 providers:providers,
                                                                 provider_count: chainConfig.providers.count)
        options.initialize(to: chainOptions)
        defer { options.deinitializeAndDeallocate() }
        guard let provider = aws_credentials_provider_new_chain(allocator.rawValue,
                                                                nil) else {return nil}
        return createWrappedProvider(cProvider: provider, allocator: allocator)
    }
    
    func createCredentialsProviderCached(cachedConfig: CredentialsProviderCachedConfig) -> CredentialsProvider? {
        let cachedOptionsPointer = UnsafeMutablePointer<aws_credentials_provider_cached_options>.allocate(capacity: 1)
        let cachedOptions = aws_credentials_provider_cached_options(shutdown_options: cachedConfig.shutDownOptions.rawValue.pointee, source: cachedConfig.source.rawValue, refresh_time_in_milliseconds: UInt64(cachedConfig.refreshTimeMs), high_res_clock_fn: nil, system_clock_fn: nil)
        cachedOptionsPointer.initialize(to: cachedOptions)
        defer { cachedOptionsPointer.deinitializeAndDeallocate() }
        
        guard let provider = aws_credentials_provider_new_cached(allocator.rawValue, cachedOptionsPointer) else {
            return nil
        }
        
        return createWrappedProvider(cProvider: provider, allocator: allocator)
    }
    
    func createCredentialsProviderChainDefault(chainDefaultConfig: CredentialsProviderChainDefaultConfig) -> CredentialsProvider? {
        let chainDefaultOptionsPtr = UnsafeMutablePointer<aws_credentials_provider_chain_default_options>.allocate(capacity: 1)
        let chainDefaultOptions = aws_credentials_provider_chain_default_options(shutdown_options: chainDefaultConfig.shutDownOptions.rawValue.pointee, bootstrap: chainDefaultConfig.bootstrap.rawValue)
        chainDefaultOptionsPtr.initialize(to: chainDefaultOptions)
        defer { chainDefaultOptionsPtr.deinitializeAndDeallocate() }
        guard let provider = aws_credentials_provider_new_chain_default(allocator.rawValue, chainDefaultOptionsPtr) else {
            return nil
        }
        return createWrappedProvider(cProvider: provider, allocator: allocator)
    }
    
    func createCredentialsProviderx509(x509Config: CredentialsProviderX509Config) -> CredentialsProvider? {
        let tlsOptionsPtr = UnsafeMutablePointer<aws_tls_connection_options>.allocate(capacity: 1)
        tlsOptionsPtr.initialize(to: x509Config.tlsConnectionOptions.rawValue)
        let proxyOptionsPtr = UnsafeMutablePointer<aws_http_proxy_options>.allocate(capacity: 1)
        proxyOptionsPtr.initialize(to: x509Config.proxyOptions.rawValue)
        let x509OptionsPtr = UnsafeMutablePointer<aws_credentials_provider_x509_options>.allocate(capacity: 1)
        let x509Options = aws_credentials_provider_x509_options(shutdown_options: x509Config.shutDownOptions.rawValue.pointee,
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
        return createWrappedProvider(cProvider: provider, allocator: allocator)
    }

    deinit {
        aws_credentials_provider_release(rawValue)
    }
}
