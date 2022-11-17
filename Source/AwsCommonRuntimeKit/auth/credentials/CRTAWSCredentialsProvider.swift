//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth
import AwsCIo
import AwsCHttp
import Foundation

public protocol CredentialsProvider: AnyObject {
    func getCredentials() async throws -> AwsCredentials
}

/// A container class to wrap a protocol so that we use it with Unmanaged
class CredentialsProviderCore {
    let credentialsProvider: CredentialsProvider
    init(_ credentialsProvider: CredentialsProvider) {
        self.credentialsProvider = credentialsProvider
    }

    func passUnretained() -> UnsafeMutableRawPointer {
        return Unmanaged<CredentialsProviderCore>.passUnretained(self).toOpaque()
    }
}

//TODO: Rename file name
public class AwsCredentialsProvider: CredentialsProvider {

    let allocator: Allocator
    let rawValue: UnsafeMutablePointer<aws_credentials_provider>

    // Optional reference to delegate Get Credentials to keep it alive
    let delegateGetCredentials: CredentialsProviderCore?
    init(credentialsProvider: UnsafeMutablePointer<aws_credentials_provider>,
         allocator: Allocator,
         delegateGetCredentials: CredentialsProviderCore? = nil) {
        self.rawValue = credentialsProvider
        self.allocator = allocator
        self.delegateGetCredentials = delegateGetCredentials
    }

    /// Retrieves credentials from a provider by calling its implementation of get credentials and returns them to
    /// the callback passed in.
    ///
    /// - Returns: `Result<CRTCredentials, CRTError>`
    /// - Throws: CommonRuntimeError.crtError
    public func getCredentials() async throws -> AwsCredentials {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<AwsCredentials, Error>) in
            let continuationCore = ContinuationCore(continuation: continuation)
            if aws_credentials_provider_get_credentials(rawValue,
                                                        onGetCredentials,
                                                        continuationCore.passRetained()) != AWS_OP_SUCCESS {
                continuationCore.release()
                continuation.resume(throwing: CommonRunTimeError.crtError(CRTError.makeFromLastError()))
            }
        }
    }

    public static func makeDelegate(credentialsProvider: CredentialsProvider,
                                    allocator: Allocator = defaultAllocator,
                                    shutdownCallback: ShutdownCallback? = nil) throws -> AwsCredentialsProvider {
        let shutdownCallbackCore = ShutdownCallbackCore(shutdownCallback)
        let credentialsProviderCore = CredentialsProviderCore(credentialsProvider)
        let shutdownOptions =  shutdownCallbackCore.getRetainedCredentialProviderShutdownOptions()
        var options = aws_credentials_provider_delegate_options(shutdown_options: shutdownOptions,
                                                                get_credentials: getCredentialsDelegateFn,
                                                                delegate_user_data: credentialsProviderCore.passUnretained())

        guard let provider = aws_credentials_provider_new_delegate(allocator.rawValue, &options) else {
            shutdownCallbackCore.release()
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
        }
        return AwsCredentialsProvider(credentialsProvider: provider,
                                   allocator: allocator,
                                   delegateGetCredentials: credentialsProviderCore)
    }

    /// Creates a credentials provider containing a fixed set of credentials.
    ///
    /// - Parameters:
    ///   - accessKey: The access key to use.
    ///   - secret: The secret to use.
    ///   - sessionToken: (Optional) Session token to use.
    ///   - shutdownCallback:  (Optional) shutdown callback
    ///   - allocator: (Optional) allocator to override
    /// - Returns: `CredentialsProvider`
    /// - Throws: CommonRuntimeError.crtError
    public static func makeStatic(accessKey: String,
                                  secret: String,
                                  sessionToken: String? = nil,
                                  shutdownCallback: ShutdownCallback? = nil,
                                  allocator: Allocator = defaultAllocator) throws -> AwsCredentialsProvider {
        let shutdownCallbackCore = ShutdownCallbackCore(shutdownCallback)
        var staticOptions = aws_credentials_provider_static_options()
        staticOptions.shutdown_options = shutdownCallbackCore.getRetainedCredentialProviderShutdownOptions()
        guard let provider: UnsafeMutablePointer<aws_credentials_provider> = withByteCursorFromStrings(
                accessKey,
                secret,
                sessionToken, { accessKeyCursor, secretCursor, sessionTokenCursor in
            staticOptions.access_key_id = accessKeyCursor
            staticOptions.secret_access_key = secretCursor
            staticOptions.session_token = sessionTokenCursor
            return aws_credentials_provider_new_static(allocator.rawValue, &staticOptions)
        }) else {
            shutdownCallbackCore.release()
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
        }
        return AwsCredentialsProvider(credentialsProvider: provider, allocator: allocator)
    }

    /// Creates a credentials provider that returns credentials based on environment variable values:
    /// - `AWS_ACCESS_KEY_ID`
    /// - `AWS_SECRET_ACCESS_KEY`
    /// - `AWS_SESSION_TOKEN`
    ///
    /// - Parameters:
    ///   - shutdownCallback:  (Optional) shutdown callback.
    ///   - allocator: (Optional) allocator to override.
    /// - Returns: `CredentialsProvider`
    /// - Throws: CommonRuntimeError.crtError
    public static func makeEnvironment(shutdownCallback: ShutdownCallback? = nil,
                                       allocator: Allocator = defaultAllocator) throws -> AwsCredentialsProvider {

        let shutdownCallbackCore = ShutdownCallbackCore(shutdownCallback)
        var envOptions = aws_credentials_provider_environment_options()
        envOptions.shutdown_options = shutdownCallbackCore.getRetainedCredentialProviderShutdownOptions()
        guard let provider = aws_credentials_provider_new_environment(allocator.rawValue,
                                                                      &envOptions) else {
            shutdownCallbackCore.release()
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
        }
        return AwsCredentialsProvider(credentialsProvider: provider, allocator: allocator)
    }

    /// Creates a credentials provider that sources credentials from the aws profile and credentials files
    /// (by default ~/.aws/profile and ~/.aws/credentials)
    ///
    /// - Parameters:
    ///   - configFileNameOverride:  (Optional) Override path to the profile config file (~/.aws/config by default)
    ///   - profileFileNameOverride: (Optional) Override of what profile to use to source credentials from ('default' by default)
    ///   - credentialsFileNameOverride: (Optional) Override path to the profile credentials file (~/.aws/credentials by default)
    ///   - shutdownCallback:  (Optional) shutdown callback
    ///   - allocator: (Optional) allocator to override
    /// - Returns: `CredentialsProvider`
    /// - Throws: CommonRuntimeError.crtError
    public static func makeProfile(configFileNameOverride: String? = nil,
                                   profileFileNameOverride: String? = nil,
                                   credentialsFileNameOverride: String? = nil,
                                   shutdownCallback: ShutdownCallback? = nil,
                                   allocator: Allocator = defaultAllocator) throws -> AwsCredentialsProvider {
        let shutdownCallbackCore = ShutdownCallbackCore(shutdownCallback)
        var profileOptionsC = aws_credentials_provider_profile_options()
        profileOptionsC.shutdown_options = shutdownCallbackCore.getRetainedCredentialProviderShutdownOptions()
        guard let provider: UnsafeMutablePointer<aws_credentials_provider> = withByteCursorFromStrings(
                configFileNameOverride,
                credentialsFileNameOverride,
                profileFileNameOverride, {
            configFileNameOverrideCursor, credentialsFileNameOverrideCursor, profileFileNameOverrideCursor in
            profileOptionsC.config_file_name_override = configFileNameOverrideCursor
            profileOptionsC.credentials_file_name_override = credentialsFileNameOverrideCursor
            profileOptionsC.profile_name_override = profileFileNameOverrideCursor
            return aws_credentials_provider_new_profile(allocator.rawValue, &profileOptionsC)
        }) else {
            shutdownCallbackCore.release()
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
        }
        return AwsCredentialsProvider(credentialsProvider: provider, allocator: allocator)
    }

    /// Creates a credentials provider that sources credentials from ec2 instance metadata.
    ///
    /// - Parameters:
    ///   - bootstrap:  Connection bootstrap to use for any network connections made while sourcing credentials.
    ///   - imdsVersion:  (Optional) Which version of the imds query protocol to use.
    ///   - shutdownCallback:  (Optional) shutdown callback
    ///   - allocator: (Optional) allocator to override
    /// - Returns: `CredentialsProvider`
    /// - Throws: CommonRuntimeError.crtError
    public static func makeImds(bootstrap: ClientBootstrap,
                                imdsVersion: CRTIMDSProtocolVersion = CRTIMDSProtocolVersion.version2,
                                shutdownCallback: ShutdownCallback? = nil,
                                allocator: Allocator = defaultAllocator) throws -> AwsCredentialsProvider {
        let shutdownCallbackCore = ShutdownCallbackCore(shutdownCallback)
        var imdsOptions = aws_credentials_provider_imds_options()
        imdsOptions.bootstrap = bootstrap.rawValue
        imdsOptions.imds_version = imdsVersion.rawValue
        imdsOptions.shutdown_options = shutdownCallbackCore.getRetainedCredentialProviderShutdownOptions()
        guard let provider = aws_credentials_provider_new_imds(allocator.rawValue,
                                                               &imdsOptions) else {
            shutdownCallbackCore.release()
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
        }
        return AwsCredentialsProvider(credentialsProvider: provider, allocator: allocator)
    }

    /// Configuration options for a provider that functions as a caching decorator. Credentials sourced through this
    /// provider will be cached within it until their expiration time. When the cached credentials expire, new
    /// credentials will be fetched when next queried.
    /// - Parameters:
    ///   - source: The provider to cache credentials query results from.
    ///   - refreshTime: (Optional) expiration time period for sourced credentials. For a given set of cached credentials,
    ///     the refresh time period will be the minimum of this time and any expiration timestamp on the credentials
    ///     themselves.
    ///   - shutdownCallback:  (Optional) shutdown callback.
    ///   - allocator: (Optional) allocator to override.
    /// - Returns: `CredentialsProvider`
    /// - Throws: CommonRuntimeError.crtError
    public static func makeCached(source: AwsCredentialsProvider,
                                  refreshTime: TimeInterval = 0,
                                  shutdownCallback: ShutdownCallback? = nil,
                                  allocator: Allocator = defaultAllocator) throws -> AwsCredentialsProvider {
        let shutdownCallbackCore = ShutdownCallbackCore(shutdownCallback)

        var cachedOptions = aws_credentials_provider_cached_options()
        cachedOptions.source = source.rawValue
        cachedOptions.refresh_time_in_milliseconds = refreshTime.millisecond
        cachedOptions.shutdown_options = shutdownCallbackCore.getRetainedCredentialProviderShutdownOptions()

        guard let provider = aws_credentials_provider_new_cached(allocator.rawValue, &cachedOptions) else {
            shutdownCallbackCore.release()
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
        }
        return AwsCredentialsProvider(credentialsProvider: provider, allocator: allocator)
    }

    /// Creates the default provider chain used by most AWS SDKs.
    /// Generally:
    /// - Environment
    /// - Profile
    /// - (conditional, off by default) ECS
    /// - (conditional, on by default) EC2 Instance Metadata
    /// Support for environmental control of the default provider chain is not yet implemented.
    ///
    /// - Parameters:
    ///   - bootstrap:  Connection bootstrap to use for any network connections made while sourcing credentials.
    ///   - shutdownCallback:  (Optional) shutdown callback
    ///   - allocator: (Optional) allocator to override
    /// - Returns: `CredentialsProvider`
    /// - Throws: CommonRuntimeError.crtError
    public static func makeDefaultChain(bootstrap: ClientBootstrap,
                                        shutdownCallback: ShutdownCallback? = nil,
                                        allocator: Allocator = defaultAllocator) throws -> AwsCredentialsProvider {
        let shutdownCallbackCore = ShutdownCallbackCore(shutdownCallback)

        var chainDefaultOptions = aws_credentials_provider_chain_default_options()
        chainDefaultOptions.bootstrap = bootstrap.rawValue
        chainDefaultOptions.shutdown_options = shutdownCallbackCore.getRetainedCredentialProviderShutdownOptions()

        guard let provider = aws_credentials_provider_new_chain_default(allocator.rawValue,
                                                                        &chainDefaultOptions) else {
            shutdownCallbackCore.release()
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
        }
        return AwsCredentialsProvider(credentialsProvider: provider, allocator: allocator)
    }

    /// Creates a credentials provider that sources credentials from IoT Core.
    /// The x509 credentials provider sources temporary credentials from AWS IoT Core using TLS mutual authentication.<br>
    /// See details: [link](https://docs.aws.amazon.com/iot/latest/developerguide/authorizing-direct-aws.html)<br>
    /// For an end to end demo with detailed steps:
    /// [link](https://tinyurl.com/ewd66jbf)
    ///
    /// - Parameters:
    ///   - bootstrap: Connection bootstrap to use for any network connections made while sourcing credentials.
    ///   - tlsConnectionOptions: TLS connection options that have been initialized with your x509 certificate and private key.
    ///   - thingName: IoT thing name you registered with AWS IOT for your device, it will be used in http request header.
    ///   - roleAlias: Iot role alias you created with AWS IoT for your IAM role, it will be used in http request path.
    ///   - endpoint: Per-account X509 credentials sourcing endpoint.
    ///   - proxyOptions: (Optional) Http proxy configuration for the http request that fetches credentials.
    ///   - shutdownCallback: (Optional) shutdown callback
    ///   - allocator: (Optional) allocator to override
    /// - Returns: `CredentialsProvider`
    /// - Throws: CommonRuntimeError.crtError
    public static func makeX509(bootstrap: ClientBootstrap,
                                tlsConnectionOptions: TlsConnectionOptions,
                                thingName: String,
                                roleAlias: String,
                                endpoint: String,
                                proxyOptions: HttpProxyOptions? = nil,
                                shutdownCallback: ShutdownCallback? = nil,
                                allocator: Allocator = defaultAllocator) throws -> AwsCredentialsProvider {
        let shutdownCallbackCore = ShutdownCallbackCore(shutdownCallback)

        var x509Options = aws_credentials_provider_x509_options()
        x509Options.bootstrap = bootstrap.rawValue
        x509Options.shutdown_options = shutdownCallbackCore.getRetainedCredentialProviderShutdownOptions()

        guard let provider: UnsafeMutablePointer<aws_credentials_provider> = (withByteCursorFromStrings(
                thingName,
                roleAlias,
                endpoint) { thingNameCursor, roleAliasCursor, endPointCursor in
            x509Options.thing_name = thingNameCursor
            x509Options.role_alias = roleAliasCursor
            x509Options.endpoint = endPointCursor
            return withOptionalCStructPointer(proxyOptions,
                                              tlsConnectionOptions) { proxyOptionsPointer,
                                                                      tlsConnectionOptionsPointer in
                x509Options.proxy_options = proxyOptionsPointer
                x509Options.tls_connection_options = tlsConnectionOptionsPointer
                return aws_credentials_provider_new_x509(allocator.rawValue, &x509Options)
            }
        }) else {
            shutdownCallbackCore.release()
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
        }
        return AwsCredentialsProvider(credentialsProvider: provider, allocator: allocator)
    }

    /// Creates a provider that sources credentials from STS using AssumeRoleWithWebIdentity
    ///
    /// Sts with web identity credentials provider sources a set of temporary security credentials for users who have been
    /// authenticated in a mobile or web application with a web identity provider.
    /// Example providers include Amazon Cognito, Login with Amazon, Facebook, Google, or any OpenID Connect-compatible
    /// identity provider like Elastic Kubernetes Service
    /// https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRoleWithWebIdentity.html
    /// The required parameters used in the request (region, roleArn, sessionName, tokenFilePath) are automatically resolved
    /// by SDK from envrionment variables or config file.
    /// <pre>
    /// ----------------------------------------------------------------------------------<br>
    /// | Parameter           | Environment Variable Name    | Config File Property Name |<br>
    /// |---------------------|------------------------------|---------------------------|<br>
    /// | region              | AWS_DEFAULT_REGION           | region                    |<br>
    /// | role_arn            | AWS_ROLE_ARN                 | role_arn                  |<br>
    /// | role_session_name   | AWS_ROLE_SESSION_NAME        | role_session_name         |<br>
    /// | token_file_path     | AWS_WEB_IDENTITY_TOKEN_FILE  | web_identity_token_file   |<br>
    /// ----------------------------------------------------------------------------------<br>
    /// </pre>
    /// - Parameters:
    ///   - bootstrap: Connection bootstrap to use for any network connections made while sourcing credentials.
    ///   - tlsContext: Client TLS context to use when querying STS web identity provider.
    ///   - shutdownCallback:  (Optional) shutdown callback
    ///   - allocator: (Optional) allocator to override
    /// - Returns: `CredentialsProvider`
    /// - Throws: CommonRuntimeError.crtError
    public static func makeSTSWebIdentity(bootstrap: ClientBootstrap,
                                          tlsContext: TlsContext,
                                          shutdownCallback: ShutdownCallback? = nil,
                                          allocator: Allocator = defaultAllocator) throws -> AwsCredentialsProvider {
        let shutdownCallbackCore = ShutdownCallbackCore(shutdownCallback)
        var stsOptions = aws_credentials_provider_sts_web_identity_options()
        stsOptions.bootstrap = bootstrap.rawValue
        stsOptions.tls_ctx = tlsContext.rawValue
        stsOptions.shutdown_options = shutdownCallbackCore.getRetainedCredentialProviderShutdownOptions()

        guard let provider = aws_credentials_provider_new_sts_web_identity(allocator.rawValue,
                                                                           &stsOptions) else {
            shutdownCallbackCore.release()
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
        }
        return AwsCredentialsProvider(credentialsProvider: provider, allocator: allocator)
    }

    /// Creates a provider that assumes an IAM role via. STS AssumeRole() API. This provider will fetch new credentials
    /// upon each call to `getCredentials`
    /// - Parameters:
    ///   - bootstrap: Connection bootstrap to use for any network connections made while sourcing credentials.
    ///   - tlsContext: Client TLS context to use when querying STS web identity provider.
    ///   - credentialsProvider: Credentials provider to be used to sign the requests made to STS to fetch credentials.
    ///   - roleArn: Arn of the role to assume by fetching credentials for.
    ///   - sessionName: Assumed role session identifier to be associated with the sourced credentials.
    ///   - duration: How long sourced credentials should remain valid for, in seconds. 900 is the minimum allowed value.
    ///   - shutdownCallback:  (Optional) shutdown callback
    ///   - allocator: (Optional) allocator to override
    /// - Returns: `CredentialsProvider`
    /// - Throws: CommonRuntimeError.crtError
    public static func makeSTS(bootstrap: ClientBootstrap,
                               tlsContext: TlsContext,
                               credentialsProvider: AwsCredentialsProvider,
                               roleArn: String,
                               sessionName: String,
                               duration: TimeInterval,
                               shutdownCallback: ShutdownCallback? = nil,
                               allocator: Allocator = defaultAllocator) throws -> AwsCredentialsProvider {
        let shutdownCallbackCore = ShutdownCallbackCore(shutdownCallback)
        var stsOptions = aws_credentials_provider_sts_options()
        stsOptions.tls_ctx = tlsContext.rawValue
        stsOptions.creds_provider = credentialsProvider.rawValue
        stsOptions.duration_seconds = UInt16(duration)
        stsOptions.shutdown_options = shutdownCallbackCore.getRetainedCredentialProviderShutdownOptions()

        guard let provider: UnsafeMutablePointer<aws_credentials_provider> = withByteCursorFromStrings(
                roleArn,
                sessionName, { roleArnCursor, sessionNameCursor in
            stsOptions.role_arn = roleArnCursor
            stsOptions.session_name = sessionNameCursor
            return aws_credentials_provider_new_sts(allocator.rawValue, &stsOptions)
        }) else {
            shutdownCallbackCore.release()
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
        }
        return AwsCredentialsProvider(credentialsProvider: provider, allocator: allocator)
    }

    /// Credential Provider that sources credentials from ECS container metadata
    /// ECS creds provider can be used to access creds via either relative uri to a fixed endpoint http://169.254.170.2,
    /// or via a full uri specified by environment variables:
    /// - AWS_CONTAINER_CREDENTIALS_RELATIVE_URI
    /// - AWS_CONTAINER_CREDENTIALS_FULL_URI
    /// - AWS_CONTAINER_AUTHORIZATION_TOKEN
    ///
    /// If both relative uri and absolute uri are set, relative uri has higher priority.
    /// Token is used in auth header but only for absolute uri.
    /// While above information is used in request only, endpoint info is needed when creating ecs provider to initiate the connection
    /// manager, more specifically, host and http scheme (tls or not) from endpoint are needed.
    ///  - Parameters:
    ///    - bootstrap: Connection bootstrap to use for any network connections made while sourcing credentials
    ///    - tlsContext: (Optional) Client TLS context to use when querying STS web identity provider.
    ///                  If set, port 443 is used. If NULL, port 80 is used.
    ///    - authToken: Authorization token to include in the credentials query.
    ///    - pathAndQuery: Http path and query string for the credentials query.
    ///    - host: Host to query credentials from.
    ///   - shutdownCallback:  (Optional) shutdown callback
    ///   - allocator: (Optional) allocator to override
    /// - Returns: `CredentialsProvider`
    /// - Throws: CommonRuntimeError.crtError
    public static func makeECS(bootstrap: ClientBootstrap,
                               tlsContext: TlsContext? = nil,
                               authToken: String,
                               pathAndQuery: String,
                               host: String,
                               shutdownCallback: ShutdownCallback? = nil,
                               allocator: Allocator = defaultAllocator) throws -> AwsCredentialsProvider {
        let shutdownCallbackCore = ShutdownCallbackCore(shutdownCallback)
        var ecsOptions = aws_credentials_provider_ecs_options()
        ecsOptions.tls_ctx = tlsContext?.rawValue
        ecsOptions.bootstrap = bootstrap.rawValue
        ecsOptions.shutdown_options = shutdownCallbackCore.getRetainedCredentialProviderShutdownOptions()

        guard let provider: UnsafeMutablePointer<aws_credentials_provider> = (withByteCursorFromStrings(
                host,
                authToken,
                pathAndQuery) { hostCursor, authTokenCursor, pathAndQueryCursor in
            ecsOptions.host = hostCursor
            ecsOptions.auth_token = authTokenCursor
            ecsOptions.path_and_query = pathAndQueryCursor
            return aws_credentials_provider_new_ecs(allocator.rawValue, &ecsOptions)
        }) else {
            shutdownCallbackCore.release()
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
        }
        return AwsCredentialsProvider(credentialsProvider: provider, allocator: allocator)
    }

    deinit {
        aws_credentials_provider_release(rawValue)
    }
}

private func onGetCredentials(credentials: OpaquePointer?,
                              errorCode: Int32,
                              userData: UnsafeMutableRawPointer!) {

    let continuationCore = Unmanaged<ContinuationCore<AwsCredentials>>.fromOpaque(userData).takeRetainedValue()

    if errorCode != AWS_OP_SUCCESS {
        continuationCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
        return
    }

    //Success
    continuationCore.continuation.resume(returning: AwsCredentials(rawValue: credentials!))
}

private func getCredentialsDelegateFn(_ delegatePtr: UnsafeMutableRawPointer!,
                                      _ callbackFn: (@convention(c)(OpaquePointer?, Int32, UnsafeMutableRawPointer?) -> Void)!,
                                      _ userData: UnsafeMutableRawPointer!) -> Int32 {
    let credentialsProvider = Unmanaged<CredentialsProviderCore>.fromOpaque(delegatePtr)
                                                                .takeUnretainedValue()
                                                                .credentialsProvider
    Task {
        do {
            let credentials = try await credentialsProvider.getCredentials()
            callbackFn(credentials.rawValue, AWS_OP_SUCCESS, userData)
        } catch CommonRunTimeError.crtError(let crtError) {
            callbackFn(nil, crtError.code, userData)
        } catch {
            callbackFn(nil, Int32(AWS_AUTH_CREDENTIALS_PROVIDER_DELEGATE_FAILURE.rawValue), userData)
        }
    }

    return AWS_OP_SUCCESS
}
