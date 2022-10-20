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
                            allocator: Allocator = defaultAllocator,
                            shutdownCallback: ShutdownCallback? = nil) throws {
        let shutdownCallbackCore = ShutdownCallbackCore(shutdownCallback)
        let shutdownOptions =  shutdownCallbackCore.getRetainedCredentialProviderShutdownOptions()
        let credProviderPtr: UnsafeMutablePointer<CRTCredentialsProvider> = fromPointer(ptr: impl)
        var options = aws_credentials_provider_delegate_options(shutdown_options: shutdownOptions,
                                                                get_credentials: getCredentialsDelegateFn,
                                                                delegate_user_data: credProviderPtr)

        guard let credProvider = aws_credentials_provider_new_delegate(allocator.rawValue, &options) else {
            shutdownCallbackCore.release()
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

        let shutdownCallbackCore = ShutdownCallbackCore(config.shutdownCallback)
        var staticOptions = aws_credentials_provider_static_options()
        staticOptions.shutdown_options = shutdownCallbackCore.getRetainedCredentialProviderShutdownOptions()
        guard let provider: UnsafeMutablePointer<aws_credentials_provider> = withByteCursorFromStrings(
                config.accessKey,
                config.secret,
                config.sessionToken ?? "", { accessKeyCursor, secretCursor, sessionTokenCursor in
            staticOptions.access_key_id = accessKeyCursor
            staticOptions.secret_access_key = secretCursor
            staticOptions.session_token = sessionTokenCursor
            return aws_credentials_provider_new_static(allocator.rawValue, &staticOptions)
        }) else {
            shutdownCallbackCore.release()
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
        }
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
    public convenience init(fromEnv shutdownCallback: ShutdownCallback?,
                            allocator: Allocator = defaultAllocator) throws {

        let shutdownCallbackCore = ShutdownCallbackCore(shutdownCallback)
        var envOptions = aws_credentials_provider_environment_options()
        envOptions.shutdown_options = shutdownCallbackCore.getRetainedCredentialProviderShutdownOptions()

        guard let provider = aws_credentials_provider_new_environment(allocator.rawValue,
                                                                      &envOptions)
        else {
            shutdownCallbackCore.release()
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
        }
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
        let shutdownCallbackCore = ShutdownCallbackCore(profileOptions.shutdownCallback)
        var profileOptionsC = aws_credentials_provider_profile_options()

        profileOptionsC.shutdown_options = shutdownCallbackCore.getRetainedCredentialProviderShutdownOptions()
        guard let provider: UnsafeMutablePointer<aws_credentials_provider> = withByteCursorFromStrings(
                profileOptions.configFileNameOverride ?? "",
                profileOptions.credentialsFileNameOverride ?? "",
                profileOptions.profileFileNameOverride ?? "", {
            configFileNameOverrideCursor, credentialsFileNameOverrideCursor, profileFileNameOverrideCursor in
            profileOptionsC.config_file_name_override = configFileNameOverrideCursor
            profileOptionsC.credentials_file_name_override = credentialsFileNameOverrideCursor
            profileOptionsC.profile_name_override = profileFileNameOverrideCursor
            return aws_credentials_provider_new_profile(allocator.rawValue, &profileOptionsC)
        }) else {
            shutdownCallbackCore.release()
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())//
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
        let shutdownCallbackCore = ShutdownCallbackCore(imdsConfig.shutdownCallback)
        var imdsOptions = aws_credentials_provider_imds_options()
        imdsOptions.bootstrap = imdsConfig.bootstrap.rawValue
        imdsOptions.shutdown_options = shutdownCallbackCore.getRetainedCredentialProviderShutdownOptions()

        guard let provider = aws_credentials_provider_new_imds(allocator.rawValue,
                                                               &imdsOptions) else {
            shutdownCallbackCore.release()
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
        }
        self.init(credentialsProvider: provider, allocator: allocator)
    }

    /// Creates a credentials provider that functions as a caching decorating of another provider.
    ///
    /// - Parameters:
    ///   - cachedConfig:  The `CredentialsProviderCachedConfig`options object.
    ///   - allocator: defaultAllocator
    /// - Returns: `AWSCredentialsProvider`
    public convenience init(fromCached cachedConfig: inout CRTCredentialsProviderCachedConfig,
                            allocator: Allocator = defaultAllocator) throws {
        let shutdownCallbackCore = ShutdownCallbackCore(cachedConfig.shutdownCallback)

        var cachedOptions = aws_credentials_provider_cached_options()
        cachedOptions.shutdown_options = shutdownCallbackCore.getRetainedCredentialProviderShutdownOptions()

        cachedOptions.source = cachedConfig.source.rawValue
        cachedOptions.refresh_time_in_milliseconds = cachedConfig.refreshTime.millisecond

        guard let provider = aws_credentials_provider_new_cached(allocator.rawValue, &cachedOptions) else {
            shutdownCallbackCore.release()
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
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
        let shutdownCallbackCore = ShutdownCallbackCore(chainDefaultConfig.shutdownCallback)

        var chainDefaultOptions = aws_credentials_provider_chain_default_options()
        chainDefaultOptions.shutdown_options = shutdownCallbackCore.getRetainedCredentialProviderShutdownOptions()
        chainDefaultOptions.bootstrap = chainDefaultConfig.bootstrap.rawValue

        guard let provider = aws_credentials_provider_new_chain_default(allocator.rawValue,
                                                                        &chainDefaultOptions) else {
            shutdownCallbackCore.release()
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
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
        let shutdownCallbackCore = ShutdownCallbackCore(x509Config.shutdownCallback)

        var x509Options = aws_credentials_provider_x509_options()
        x509Options.shutdown_options = shutdownCallbackCore.getRetainedCredentialProviderShutdownOptions()
        x509Options.bootstrap = x509Config.bootstrap.rawValue
        x509Options.tls_connection_options = UnsafePointer(x509Config.tlsConnectionOptions.rawValue)
        if let proxyOptions = x509Config.proxyOptions?.rawValue {
            x509Options.proxy_options = UnsafePointer(proxyOptions)
        }

        guard let provider: UnsafeMutablePointer<aws_credentials_provider> = (withByteCursorFromStrings(
                x509Config.thingName,
                x509Config.roleAlias,
                x509Config.endpoint) { thingNameCursor, roleAliasCursor, endPointCursor in
            x509Options.thing_name = thingNameCursor
            x509Options.role_alias = roleAliasCursor
            x509Options.endpoint = endPointCursor
            return aws_credentials_provider_new_x509(allocator.rawValue, &x509Options)
        }) else {
            shutdownCallbackCore.release()
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
        }
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
        let shutdownCallbackCore = ShutdownCallbackCore(webIdentityConfig.shutdownCallback)
        var stsOptions = aws_credentials_provider_sts_web_identity_options()
        stsOptions.bootstrap = webIdentityConfig.bootstrap.rawValue
        stsOptions.shutdown_options = shutdownCallbackCore.getRetainedCredentialProviderShutdownOptions()
        stsOptions.tls_ctx = webIdentityConfig.tlsContext.rawValue
        stsOptions.function_table = nil
        guard let provider = aws_credentials_provider_new_sts_web_identity(allocator.rawValue,
                                                                           &stsOptions) else {
            shutdownCallbackCore.release()
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
        }
        self.init(credentialsProvider: provider, allocator: allocator)
    }

    /// Creates a provider that assumes an IAM role via. STS AssumeRole() API. This provider will fetch new credentials
    /// upon each call to `getCredentials`
    ///
    /// - Parameters:
    ///    - stsConfig: The `CRTCredentialsProviderSTSConfig` options object
    ///    - allocator: Allocator
    /// - Returns: `AWSCredentialsProvider`
    public convenience init(fromSTS stsConfig: CRTCredentialsProviderSTSConfig,
                            allocator: Allocator = defaultAllocator) throws {
        let shutdownCallbackCore = ShutdownCallbackCore(stsConfig.shutdownCallback)
        var stsOptions = aws_credentials_provider_sts_options()
        stsOptions.tls_ctx = stsConfig.tlsContext.rawValue
        stsOptions.shutdown_options = shutdownCallbackCore.getRetainedCredentialProviderShutdownOptions()
        stsOptions.creds_provider = stsConfig.credentialsProvider.rawValue
        stsOptions.duration_seconds = UInt16(stsConfig.durationSeconds)
        stsOptions.function_table = nil
        stsOptions.system_clock_fn = nil

        guard let provider: UnsafeMutablePointer<aws_credentials_provider> = withByteCursorFromStrings(
                stsConfig.roleArn,
                stsConfig.sessionName, {roleArnCursor, sessionNameCursor in
            stsOptions.role_arn = roleArnCursor
            stsOptions.session_name = sessionNameCursor
            return aws_credentials_provider_new_sts(allocator.rawValue, &stsOptions)
        }) else {
            shutdownCallbackCore.release()
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
        }
        self.init(credentialsProvider: provider, allocator: allocator)
    }

    /// Creates a provider that sources credentials from the ecs role credentials service
    ///
    ///  - Parameters:
    ///    - containerConfig: The `CRTCredentialsProviderContainerConfig` options object
    /// - Returns: `AWSCredentialsProvider`
    public convenience init(fromContainer containerConfig: CRTCredentialsProviderContainerConfig,
                            allocator: Allocator = defaultAllocator) throws {
        let shutdownCallbackCore = ShutdownCallbackCore(containerConfig.shutdownCallback)
        var ecsOptions = aws_credentials_provider_ecs_options()
        ecsOptions.tls_ctx = containerConfig.tlsContext.rawValue
        ecsOptions.shutdown_options = shutdownCallbackCore.getRetainedCredentialProviderShutdownOptions()
        ecsOptions.bootstrap = containerConfig.bootstrap.rawValue
        ecsOptions.function_table = nil

        guard let provider: UnsafeMutablePointer<aws_credentials_provider> = (withByteCursorFromStrings(
                containerConfig.host ?? "",
                containerConfig.authToken ?? "",
                containerConfig.pathAndQuery ?? "") { hostCursor, authTokenCursor, pathAndQueryCursor in
            ecsOptions.host = hostCursor
            ecsOptions.auth_token = authTokenCursor
            ecsOptions.path_and_query = pathAndQueryCursor
            return  aws_credentials_provider_new_ecs(allocator.rawValue, &ecsOptions)
        }) else {
            shutdownCallbackCore.release()
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
        }
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
        } catch {} // TODO: handle other errors
    }
    return 0
}
