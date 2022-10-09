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
                            allocator: Allocator = defaultAllocator) throws {
        let shutDownOptions = CRTAWSCredentialsProvider.setUpShutDownOptions(shutDownOptions: shutDownOptions)
        let credProviderPtr: UnsafeMutablePointer<CRTCredentialsProvider> = fromPointer(ptr: impl)
        var options = aws_credentials_provider_delegate_options(shutdown_options: shutDownOptions,
                                                                get_credentials: getCredentialsDelegateFn,
                                                                delegate_user_data: credProviderPtr)

        guard let credProvider = aws_credentials_provider_new_delegate(allocator.rawValue, &options) else {
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
        }
        self.init(credentialsProvider: credProvider, allocator: allocator)
    }

    /// Creates a credentials provider containing a fixed set of credentials.
    ///
    /// - Parameters:
    ///   - config:  The `CredentialsProviderStaticConfigOptions` config object.
    /// - Returns: `AWSCredentialsProvider`
    public convenience init(fromStatic config: CRTCredentialsProviderStaticConfigOptions,
                            allocator: Allocator = defaultAllocator) throws {

        var staticOptions = aws_credentials_provider_static_options()
        staticOptions.shutdown_options = CRTAWSCredentialsProvider.setUpShutDownOptions(
            shutDownOptions: config.shutDownOptions)
        guard let provider = withByteCursorFromStrings(config.accessKey, config.secret, config.sessionToken ?? "" , { accessKeyCursor, secretCursor, sessionTokenCursor in
            staticOptions.access_key_id = accessKeyCursor
            staticOptions.secret_access_key = secretCursor
            if let sessionToken = config.sessionToken {
                staticOptions.session_token = sessionTokenCursor
            }

            return aws_credentials_provider_new_static(allocator.rawValue,
                    &staticOptions)
        }) else {
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())        }
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
        envOptions.shutdown_options = CRTAWSCredentialsProvider.setUpShutDownOptions(shutDownOptions: shutdownOptions)

        guard let provider = aws_credentials_provider_new_environment(allocator.rawValue,
                                                                      &envOptions)
        else { throw CommonRunTimeError.crtError(CRTError.makeFromLastError()) }
        self.init(credentialsProvider: provider, allocator: allocator)
    }

//    /// Creates a credentials provider that sources credentials from key-value profiles loaded from the aws credentials
//    /// file ("~/.aws/credentials" by default) and the aws config file ("~/.aws/config" by default)
//    ///
//    /// - Parameters:
//    ///   - profileOptions:  The `CredentialsProviderProfileOptions`options object.
//    /// - Returns: `AWSCredentialsProvider`
//    public convenience init(fromProfile profileOptions: CRTCredentialsProviderProfileOptions,
//                            allocator: Allocator = defaultAllocator) throws {
//
//        var profileOptionsC = aws_credentials_provider_profile_options()
//        if let configFileName = profileOptions.configFileNameOverride {
//            profileOptionsC.config_file_name_override = configFileName.awsByteCursor
//        }
//
//        if let credentialsFileName = profileOptions.credentialsFileNameOverride {
//            profileOptionsC.credentials_file_name_override = credentialsFileName.awsByteCursor
//        }
//
//        if let profileName = profileOptions.profileFileNameOverride {
//            profileOptionsC.profile_name_override = profileName.awsByteCursor
//        }
//        profileOptionsC.shutdown_options = CRTAWSCredentialsProvider.setUpShutDownOptions(shutDownOptions: profileOptions.shutdownOptions)
//
//        guard let provider = aws_credentials_provider_new_profile(allocator.rawValue,
//                                                                  &profileOptionsC) else {
//            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())//
//        }
//
//        self.init(credentialsProvider: provider, allocator: allocator)
//    }

    /// Creates a credentials provider from the ec2 instance metadata service
    ///
    /// - Parameters:
    ///   - imdsConfig:  The `CredentialsProviderImdsConfig`options object.
    /// - Returns: `AWSCredentialsProvider`
    public convenience init(fromImds imdsConfig: CRTCredentialsProviderImdsConfig,
                            allocator: Allocator = defaultAllocator) throws {

        var imdsOptions = aws_credentials_provider_imds_options()
        imdsOptions.bootstrap = imdsConfig.bootstrap.rawValue
        imdsOptions.shutdown_options = CRTAWSCredentialsProvider.setUpShutDownOptions(
            shutDownOptions: imdsConfig.shutdownOptions)

        guard let provider = aws_credentials_provider_new_imds(
                allocator.rawValue,
                &imdsOptions) else {
                throw CommonRunTimeError.crtError(CRTError.makeFromLastError())}
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
        cachedOptions.shutdown_options = CRTAWSCredentialsProvider.setUpShutDownOptions(
            shutDownOptions: cachedConfig.shutDownOptions)

        cachedOptions.source = cachedConfig.source.rawValue
        cachedOptions.refresh_time_in_milliseconds = UInt64(cachedConfig.refreshTime)

        guard let provider = aws_credentials_provider_new_cached(allocator.rawValue, &cachedOptions) else {
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())        }
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
        chainDefaultOptions.shutdown_options = CRTAWSCredentialsProvider.setUpShutDownOptions(
            shutDownOptions: chainDefaultConfig.shutDownOptions)
        chainDefaultOptions.bootstrap = chainDefaultConfig.bootstrap.rawValue

        guard let provider = aws_credentials_provider_new_chain_default(allocator.rawValue,
                                                                        &chainDefaultOptions) else {
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())        }
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
        x509Options.shutdown_options = CRTAWSCredentialsProvider.setUpShutDownOptions(
            shutDownOptions: x509Config.shutDownOptions)
        //Todo: fix
//        x509Options.bootstrap = x509Config.bootstrap.rawValue
//        x509Options.tls_connection_options = UnsafePointer(x509Config.tlsConnectionOptions.rawValue)
//        x509Options.thing_name = x509Config.thingName.awsByteCursor
//        x509Options.role_alias = x509Config.roleAlias.awsByteCursor
//        x509Options.endpoint = x509Config.endpoint.awsByteCursor

        if let proxyOptions = x509Config.proxyOptions?.rawValue {
            x509Options.proxy_options = UnsafePointer(proxyOptions)
        }

        guard let provider = aws_credentials_provider_new_x509(allocator.rawValue,
                                                               &x509Options) else {
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())        }
        self.init(credentialsProvider: provider, allocator: allocator)
    }
#endif

    /// Creates a provider that sources credentials from STS using AssumeRoleWithWebIdentity
    ///
    /// - Parameters:
    ///    - webIdentityConfig: The `CRTCredentialsProviderWebIdentityConfig` options object.
    /// - Returns: `AWSCredentialsProvider`
    public convenience init(fromWebIdentity webIdentityConfig: CRTCredentialsProviderWebIdentityConfig,
                            allocator: Allocator = defaultAllocator) throws {
        var stsOptions = aws_credentials_provider_sts_web_identity_options()
        stsOptions.bootstrap = webIdentityConfig.bootstrap.rawValue
        stsOptions.shutdown_options = CRTAWSCredentialsProvider.setUpShutDownOptions(
            shutDownOptions: webIdentityConfig.shutDownOptions)
        stsOptions.tls_ctx = webIdentityConfig.tlsContext.rawValue
        stsOptions.function_table = nil
        guard let provider = aws_credentials_provider_new_sts_web_identity(allocator.rawValue,
                                                                           &stsOptions) else {
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())        }
        self.init(credentialsProvider: provider, allocator: allocator)
    }

    /// Creates a provider that assumes an IAM role via. STS AssumeRole() API. This provider will fetch new credentials
    /// upon each call to `getCredentials`
    ///
    /// - Parameters:
    ///    - stsConfig: The `CRTCredentialsProviderSTSConfig` options object
    /// - Returns: `AWSCredentialsProvider`
    public convenience init(fromSTS stsConfig: CRTCredentialsProviderSTSConfig,
                            allocator: Allocator = defaultAllocator) throws {
        var stsOptions = aws_credentials_provider_sts_options()
        //Todo: fix
//        stsOptions.tls_ctx = stsConfig.tlsContext.rawValue
//        stsOptions.shutdown_options = CRTAWSCredentialsProvider.setUpShutDownOptions(
//            shutDownOptions: stsConfig.shutDownOptions)
//        stsOptions.creds_provider = stsConfig.credentialsProvider.rawValue
//        stsOptions.role_arn = stsConfig.roleArn.awsByteCursor
//        stsOptions.session_name = stsConfig.sessionName.awsByteCursor
//        stsOptions.duration_seconds = stsConfig.durationSeconds
//        stsOptions.function_table = nil
//        stsOptions.system_clock_fn = nil

        guard let provider = aws_credentials_provider_new_sts(allocator.rawValue, &stsOptions) else {
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())        }
        self.init(credentialsProvider: provider, allocator: allocator)
    }

    /// Creates a provider that sources credentials from the ecs role credentials service
    ///
    ///  - Parameters:
    ///    - containerConfig: The `CRTCredentialsProviderContainerConfig` options object
    /// - Returns: `AWSCredentialsProvider`
    public convenience init(fromContainer containerConfig: CRTCredentialsProviderContainerConfig,
                            allocator: Allocator = defaultAllocator) throws {
        var ecsOptions = aws_credentials_provider_ecs_options()
        //Todo: fix
//        ecsOptions.tls_ctx = containerConfig.tlsContext.rawValue
//        ecsOptions.shutdown_options = CRTAWSCredentialsProvider.setUpShutDownOptions(
//            shutDownOptions: containerConfig.shutDownOptions)
//        ecsOptions.bootstrap = containerConfig.bootstrap.rawValue
//        if let host = containerConfig.host {
//            ecsOptions.host = host.awsByteCursor
//        }
//        if let authToken = containerConfig.authToken {
//            ecsOptions.auth_token = authToken.awsByteCursor
//        }
//        if let pathAndQuery = containerConfig.pathAndQuery {
//            ecsOptions.path_and_query = pathAndQuery.awsByteCursor
//        }
//        ecsOptions.function_table = nil

        guard let provider = aws_credentials_provider_new_ecs(allocator.rawValue, &ecsOptions) else {
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())        }
        self.init(credentialsProvider: provider, allocator: allocator)
    }

    /// Retrieves credentials from a provider by calling its implementation of get credentials and returns them to
    /// the callback passed in.
    ///
    /// - Returns: `Result<CRTCredentials, CRTError>`
    public func getCredentials() async throws -> CRTCredentials {
        return try await withCheckedThrowingContinuation { (continuation: CredentialsContinuation) in
            getCredentialsFromCRT(continuation: continuation)
        }
    }

    private func getCredentialsFromCRT(continuation: CredentialsContinuation) {
        let callbackData = CRTCredentialsProviderCallbackData(continuation: continuation)
        let pointer: UnsafeMutablePointer<CRTCredentialsProviderCallbackData> = fromPointer(ptr: callbackData)
        aws_credentials_provider_get_credentials(rawValue, { (credentials, errorCode, userdata) -> Void in
            guard let userdata = userdata else {
                return
            }
            let pointer = userdata.assumingMemoryBound(to: CRTCredentialsProviderCallbackData.self)
            defer { pointer.deinitializeAndDeallocate() }

            if errorCode == 0,
               let credentials = credentials,
               let crtCredentials = CRTCredentials(rawValue: credentials) {
                pointer.pointee.continuation?.resume(returning: crtCredentials)
            } else {
                pointer.pointee.continuation?.resume(throwing: CommonRunTimeError.crtError(CRTError(errorCode: errorCode)))
            }

        }, pointer)
    }

    static func setUpShutDownOptions(shutDownOptions: CRTCredentialsProviderShutdownOptions?)
    -> aws_credentials_provider_shutdown_options {

        let pointer: UnsafeMutablePointer<CRTCredentialsProviderShutdownOptions>? = fromOptionalPointer(ptr: shutDownOptions)
        let shutDownOptionsC = aws_credentials_provider_shutdown_options(shutdown_callback: { userData in
            guard let userData = userData else {
                return
            }
            let pointer = userData.assumingMemoryBound(to: CRTCredentialsProviderShutdownOptions.self)
            pointer.pointee.shutDownCallback()
            pointer.deinitializeAndDeallocate()
        }, shutdown_user_data: pointer)

        return shutDownOptionsC
    }

    deinit {
        aws_credentials_provider_release(rawValue)
    }
}

private func getCredentialsDelegateFn(_ delegatePtr: UnsafeMutableRawPointer?,
                                      _ callbackFn: (@convention(c)(OpaquePointer?, Int32, UnsafeMutableRawPointer?) -> Void)?,
                                      _ userData: UnsafeMutableRawPointer?) -> Int32 {
    guard let credentialsProvider = delegatePtr?.assumingMemoryBound(to: CRTCredentialsProvider.self) else {
        return 1
    }
    guard let credentialCallbackData = userData?.assumingMemoryBound(to: CRTCredentialsProviderCallbackData.self) else {
        return 1
    }
    let callbackPointer = UnsafeMutablePointer<CRTCredentialsProviderCallbackData>.allocate(capacity: 1)
    callbackPointer.initialize(to: credentialCallbackData.pointee)
    Task {
        do {
            let credentials = try await credentialsProvider.pointee.getCredentials()
            callbackFn?(credentials.rawValue, 0, callbackPointer)
        } catch let crtError as CRTError {
            callbackFn?(nil, crtError.code, callbackPointer)
        } catch {} //TODO: handle other errors
    }
    return 0
}
