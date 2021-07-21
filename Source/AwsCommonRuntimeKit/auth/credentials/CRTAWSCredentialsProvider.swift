//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth
import AwsCIo
import AwsCHttp

public final class CRTAWSCredentialsProvider {

    let allocator: Allocator

    var rawValue: UnsafeMutablePointer<aws_credentials_provider>

    init(credentialsProvider: UnsafeMutablePointer<aws_credentials_provider>,
         allocator: Allocator) {
        self.rawValue = credentialsProvider
        self.allocator = allocator
    }

    public convenience init(fromProvider impl: CRTCredentialsProvider,
                            shutDownOptions: CRTCredentialsProviderShutdownOptions? = nil,
                            allocator: Allocator = defaultAllocator) {
        let wrapped = WrappedCRTCredentialsProvider(impl: impl, allocator: allocator, shutDownOptions: shutDownOptions)
        self.init(credentialsProvider: &wrapped.rawValue, allocator: wrapped.allocator)
    }

    /// Creates a credentials provider containing a fixed set of credentials.
    ///
    /// - Parameters:
    ///   - config:  The `CredentialsProviderStaticConfigOptions` config object.
    /// - Returns: `AWSCredentialsProvider`
    public convenience init(fromStatic config: CRTCredentialsProviderStaticConfigOptions,
                            allocator: Allocator = defaultAllocator) throws {

        var staticOptions = aws_credentials_provider_static_options()
        staticOptions.shutdown_options = WrappedCRTCredentialsProvider.setUpShutDownOptions(
            shutDownOptions: config.shutDownOptions)
        staticOptions.access_key_id = config.accessKey.awsByteCursor
        staticOptions.secret_access_key = config.secret.awsByteCursor
        staticOptions.session_token = config.sessionToken.awsByteCursor

        guard let provider = aws_credentials_provider_new_static(allocator.rawValue,
                                                                 &staticOptions) else { throw AWSCommonRuntimeError() }

        self.init(credentialsProvider: provider, allocator: allocator)
    }

    /// Creates a credentials provider from environment variables:
    /// - `AWS_ACCESS_KEY_ID`
    /// - `AWS_SECRET_ACCESS_KEY`
    /// - `AWS_SESSION_TOKEN`
    ///
    /// - Parameters:
    ///   - shutdownOptions:  The `CredentialsProviderShutdownOptions`options object.
    /// - Returns: `AWSCredentialsProvider`
    public convenience init(fromEnv shutdownOptions: CRTCredentialsProviderShutdownOptions?,
                            allocator: Allocator = defaultAllocator) throws {

        var envOptions = aws_credentials_provider_environment_options()
        envOptions.shutdown_options = WrappedCRTCredentialsProvider.setUpShutDownOptions(shutDownOptions:
                                                                                            shutdownOptions)

        guard let provider = aws_credentials_provider_new_environment(allocator.rawValue,
                                                                      &envOptions)
        else { throw AWSCommonRuntimeError() }
        self.init(credentialsProvider: provider, allocator: allocator)
    }

    /// Creates a credentials provider that sources credentials from key-value profiles loaded from the aws credentials
    /// file ("~/.aws/credentials" by default) and the aws config file ("~/.aws/config" by default)
    ///
    /// - Parameters:
    ///   - profileOptions:  The `CredentialsProviderProfileOptions`options object.
    /// - Returns: `AWSCredentialsProvider`
    public convenience init(fromProfile profileOptions: CRTCredentialsProviderProfileOptions,
                            allocator: Allocator = defaultAllocator) throws {

        var profileOptionsC = aws_credentials_provider_profile_options()
        if let configFileName = profileOptions.configFileNameOverride {
            profileOptionsC.config_file_name_override = configFileName.awsByteCursor
        }

        if let credentialsFileName = profileOptions.credentialsFileNameOverride {
            profileOptionsC.credentials_file_name_override = credentialsFileName.awsByteCursor
        }

        if let profileName = profileOptions.profileFileNameOverride {
            profileOptionsC.profile_name_override = profileName.awsByteCursor
        }
        profileOptionsC.shutdown_options = WrappedCRTCredentialsProvider.setUpShutDownOptions(
            shutDownOptions: profileOptions.shutdownOptions)

        guard let provider = aws_credentials_provider_new_profile(allocator.rawValue,
                                                                  &profileOptionsC) else {
            throw AWSCommonRuntimeError()

        }

        self.init(credentialsProvider: provider, allocator: allocator)
    }

    /// Creates a credentials provider from the ec2 instance metadata service
    ///
    /// - Parameters:
    ///   - imdsConfig:  The `CredentialsProviderImdsConfig`options object.
    /// - Returns: `AWSCredentialsProvider`
    public convenience init(fromImds imdsConfig: CRTCredentialsProviderImdsConfig,
                            allocator: Allocator = defaultAllocator) throws {

        var imdsOptions = aws_credentials_provider_imds_options()
        imdsOptions.bootstrap = imdsConfig.bootstrap.rawValue
        imdsOptions.shutdown_options = WrappedCRTCredentialsProvider.setUpShutDownOptions(
            shutDownOptions: imdsConfig.shutdownOptions)

        guard let provider = aws_credentials_provider_new_imds(allocator.rawValue,
                                                               &imdsOptions) else {throw AWSCommonRuntimeError() }

        self.init(credentialsProvider: provider, allocator: allocator)
    }

    /// Creates a credentials provider that functions as a caching decorating of another provider.
    ///
    /// - Parameters:
    ///   - cachedConfig:  The `CredentialsProviderCachedConfig`options object.
    /// - Returns: `AWSCredentialsProvider`
    public convenience init(fromCached cachedConfig: inout CRTCredentialsProviderCachedConfig,
                            allocator: Allocator = defaultAllocator) throws {

        var cachedOptions = aws_credentials_provider_cached_options()
        cachedOptions.shutdown_options = WrappedCRTCredentialsProvider.setUpShutDownOptions(
            shutDownOptions: cachedConfig.shutDownOptions)

        cachedOptions.source = cachedConfig.source.rawValue
        cachedOptions.refresh_time_in_milliseconds = UInt64(cachedConfig.refreshTime)

        guard let provider = aws_credentials_provider_new_cached(allocator.rawValue, &cachedOptions) else {
            throw AWSCommonRuntimeError()
        }
        self.init(credentialsProvider: provider, allocator: allocator)
    }

    /// Creates the default provider chain used by most AWS SDKs.
    ///
    /// Generally:
    /// - Environment
    /// - Profile
    /// - (conditional, off by default) ECS
    /// - (conditional, on by default) EC2 Instance Metadata
    /// Support for environmental control of the default provider chain is not yet implemented.
    ///
    /// - Parameters:
    ///   - chainDefaultConfig:  The `CredentialsProviderChainDefaultConfig`options object.
    /// - Returns: `AWSCredentialsProvider`
    public convenience init(fromChainDefault chainDefaultConfig: CRTCredentialsProviderChainDefaultConfig,
                            allocator: Allocator = defaultAllocator) throws {

        var chainDefaultOptions = aws_credentials_provider_chain_default_options()
        chainDefaultOptions.shutdown_options = WrappedCRTCredentialsProvider.setUpShutDownOptions(
            shutDownOptions: chainDefaultConfig.shutDownOptions)
        chainDefaultOptions.bootstrap = chainDefaultConfig.bootstrap.rawValue

        guard let provider = aws_credentials_provider_new_chain_default(allocator.rawValue,
                                                                        &chainDefaultOptions) else {
            throw AWSCommonRuntimeError()
        }
        self.init(credentialsProvider: provider, allocator: allocator)
    }
    #if os(macOS)
    /// Creates a credentials provider that sources credentials from IoT Core.
    ///
    /// - Parameters:
    ///   - x509Config:  The `CredentialsProviderX509Config`options object.
    /// - Returns: `AWSCredentialsProvider`
    public convenience init(fromx509 x509Config: CRTCredentialsProviderX509Config,
                            allocator: Allocator = defaultAllocator) throws {

        var x509Options = aws_credentials_provider_x509_options()
        x509Options.shutdown_options = WrappedCRTCredentialsProvider.setUpShutDownOptions(
            shutDownOptions: x509Config.shutDownOptions)
        x509Options.bootstrap = x509Config.bootstrap.rawValue
        x509Options.tls_connection_options = UnsafePointer(x509Config.tlsConnectionOptions.rawValue)
        x509Options.thing_name = x509Config.thingName.awsByteCursor
        x509Options.role_alias = x509Config.roleAlias.awsByteCursor
        x509Options.endpoint = x509Config.endpoint.awsByteCursor

        if let proxyOptions = x509Config.proxyOptions?.rawValue {
            x509Options.proxy_options = UnsafePointer(proxyOptions)
        }

        guard let provider = aws_credentials_provider_new_x509(allocator.rawValue,
                                                               &x509Options) else {
            throw AWSCommonRuntimeError()
        }
        self.init(credentialsProvider: provider, allocator: allocator)
    }
    #endif

    /// Retrieves credentials from a provider by calling its implementation of get credentials and returns them to
    /// the callback passed in.
    ///
    /// - Parameters:
    ///   - credentialCallbackData:  The `CredentialProviderCallbackData`options object.
    public func getCredentials() -> Future<CRTCredentials> {
        let future = Future<CRTCredentials>()
        let callbackData = CRTCredentialsProviderCallbackData(allocator: allocator) { (crtCredentials, crtError) in
            if let crtCredentials = crtCredentials {
                future.fulfill(crtCredentials)
            } else {
                future.fail(crtError)
            }
        }
        let pointer = UnsafeMutablePointer<CRTCredentialsProviderCallbackData>.allocate(capacity: 1)
        pointer.initialize(to: callbackData)
        aws_credentials_provider_get_credentials(rawValue, { (credentials, errorCode, userdata) -> Void in
            guard let userdata = userdata else {
                return
            }
            let pointer = userdata.assumingMemoryBound(to: CRTCredentialsProviderCallbackData.self)
            defer { pointer.deinitializeAndDeallocate() }
            let error = AWSError(errorCode: errorCode)
            if let onCredentialsResolved = pointer.pointee.onCredentialsResolved {
                onCredentialsResolved(CRTCredentials(rawValue: credentials), CRTError.crtError(error))
            }
        }, pointer)
        return future
    }

    deinit {
        aws_credentials_provider_release(rawValue)
    }

}
