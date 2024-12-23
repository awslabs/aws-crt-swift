//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
@_spi(AccountIDTempSupport) @testable import AwsCommonRuntimeKit

class CredentialsProviderTests: XCBaseTestCase {
    let accessKey = "AccessKey"
    let secret = "Sekrit"
    var accountId: String? = nil
    let sessionToken = "Token"
    
    let shutdownWasCalled = XCTestExpectation(description: "Shutdown callback was called")
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func getShutdownCallback() -> ShutdownCallback {
        return {
            self.shutdownWasCalled.fulfill()
        }
    }
    
    func assertCredentials(credentials: Credentials) {
        XCTAssertEqual(accessKey, credentials.getAccessKey())
        XCTAssertEqual(secret, credentials.getSecret())
        XCTAssertEqual(sessionToken, credentials.getSessionToken())
    }
    
    func getClientBootstrap() throws -> ClientBootstrap {
        let elg = try EventLoopGroup(threadCount: 0)
        let hostResolver = try HostResolver(eventLoopGroup: elg,
                                            maxHosts: 8,
                                            maxTTL: 30)
        let bootstrap = try ClientBootstrap(eventLoopGroup: elg,
                                            hostResolver: hostResolver)
        return bootstrap
    }
    
    func getTlsContext() throws -> TLSContext {
        let options = TLSContextOptions()
        let context = try TLSContext(options: options, mode: .client)
        return context
    }
    
    func testDelegateCredentialsProvider() async throws {
        shutdownWasCalled.expectedFulfillmentCount = 2
        do {
            
            let delegateProvider: CredentialsProvider!
            // make sure actual Credentials Provider goes out of scope
            do {
                let staticProvider = try CredentialsProvider(source: .static(accessKey: accessKey,
                                                                             secret: secret,
                                                                             sessionToken: sessionToken,
                                                                             shutdownCallback: getShutdownCallback()))
                delegateProvider = try CredentialsProvider(provider: staticProvider,
                                                           shutdownCallback: getShutdownCallback())
            }
            let credentials = try await delegateProvider.getCredentials()
            XCTAssertNotNil(credentials)
            assertCredentials(credentials: credentials)
        }
        wait(for: [shutdownWasCalled], timeout: 15)
    }
    
    // TODO: change this test to not pass accountId separately once the source function handles it
    func testCreateCredentialsProviderStatic() async throws {
        accountId = "0123456789"
        do {
            let provider = try CredentialsProvider(source: .static(accessKey: accessKey,
                                                                   secret: secret,
                                                                   sessionToken: sessionToken,
                                                                   shutdownCallback: getShutdownCallback()), accountId: accountId)
            let credentials = try await provider.getCredentials()
            XCTAssertNotNil(credentials)
            assertCredentials(credentials: credentials)
        }
        wait(for: [shutdownWasCalled], timeout: 15)
    }
    
    func testCredentialsProviderEnvThrow() async {
        let exceptionWasThrown = XCTestExpectation(description: "Exception was thrown because of missing credentials in environment")
        do {
            let provider = try CredentialsProvider(source: .environment())
            _ = try await provider.getCredentials()
        } catch {
            exceptionWasThrown.fulfill()
        }
        wait(for: [exceptionWasThrown], timeout: 15)
    }
    
    func withEnvironmentCredentialsClosure<T>(closure: () async throws -> T) async rethrows -> T {
        setenv("AWS_ACCESS_KEY_ID", accessKey, 1)
        setenv("AWS_SECRET_ACCESS_KEY", secret, 1)
        setenv("AWS_SESSION_TOKEN", sessionToken, 1)
        defer {
            unsetenv("AWS_ACCESS_KEY_ID")
            unsetenv("AWS_SECRET_ACCESS_KEY")
            unsetenv("AWS_SESSION_TOKEN")
        }
        return try await closure()
    }
    
    func testCreateCredentialsProviderEnv() async throws {
        try await withEnvironmentCredentialsClosure {
            let provider = try CredentialsProvider(source: .environment())
            let credentials = try await provider.getCredentials()
            XCTAssertNotNil(credentials)
            assertCredentials(credentials: credentials)
        }
    }
    
    func testCreateCredentialsProviderProfile() async throws {
        do {
            let provider = try CredentialsProvider(source: .profile(
                bootstrap: getClientBootstrap(),
                fileBasedConfiguration: FileBasedConfiguration(
                    configFilePath: Bundle.module.path(forResource: "example_profile", ofType: "txt")!,
                    credentialsFilePath: Bundle.module.path(forResource: "example_credentials", ofType: "txt")!),
                shutdownCallback: getShutdownCallback()))
            let credentials = try await provider.getCredentials()
            XCTAssertNotNil(credentials)
            XCTAssertEqual("accessKey", credentials.getAccessKey())
            XCTAssertEqual("secretKey", credentials.getSecret())
        }
        wait(for: [shutdownWasCalled], timeout: 15)
    }
    
    func testCreateCredentialsProviderProcess() async throws {
        do {
            let provider = try CredentialsProvider(source: .process(
                fileBasedConfiguration: FileBasedConfiguration(
                    configFilePath: Bundle.module.path(forResource: "example_profile", ofType: "txt")!),
                profileFileNameOverride: "process",
                shutdownCallback: getShutdownCallback()))
            let credentials = try await provider.getCredentials()
            XCTAssertNotNil(credentials)
            XCTAssertEqual("AccessKey123", credentials.getAccessKey())
            XCTAssertEqual("SecretAccessKey123", credentials.getSecret())
            XCTAssertEqual("SessionToken123", credentials.getSessionToken())
        }
        wait(for: [shutdownWasCalled], timeout: 15)
    }
    
    func testCreateCredentialsProviderSSO() async throws {
        do {
            let provider = try CredentialsProvider(source: .sso(
                bootstrap: getClientBootstrap(),
                tlsContext: getTlsContext(),
                fileBasedConfiguration: FileBasedConfiguration(
                    configFilePath: Bundle.module.path(forResource: "example_sso_profile", ofType: "txt")!,
                    credentialsFilePath: Bundle.module.path(forResource: "example_credentials", ofType: "txt")!),
                profileFileNameOverride: "crt_user",
                shutdownCallback: getShutdownCallback()))
            XCTAssertNotNil(provider)
            // get credentials will fail in CI due to expired token, so do not assert on credentials.
            _ = try? await provider.getCredentials()
        }
        wait(for: [shutdownWasCalled], timeout: 15)
    }
    
    func testCreateCredentialsProviderImds() async throws {
        do {
            _ = try CredentialsProvider(source: .imds(bootstrap: getClientBootstrap(),
                                                      shutdownCallback: getShutdownCallback()))
        }
        wait(for: [shutdownWasCalled], timeout: 15)
    }
    
    func testCreateCredentialsProviderCache() async throws {
        do {
            let staticProvider = try CredentialsProvider(source: .static(accessKey: accessKey,
                                                                         secret: secret,
                                                                         sessionToken: sessionToken))
            let cacheProvider = try CredentialsProvider(source: .cached(source: staticProvider,
                                                                        shutdownCallback: getShutdownCallback()))
            let credentials = try await cacheProvider.getCredentials()
            XCTAssertNotNil(credentials)
            assertCredentials(credentials: credentials)
        }
        wait(for: [shutdownWasCalled], timeout: 15)
    }
    
    func testCreateAWSCredentialsProviderDefaultChain() async throws {
        try skipIfLinux()
        do {
            try await withEnvironmentCredentialsClosure {
                let provider = try CredentialsProvider(source: .defaultChain(
                    bootstrap: getClientBootstrap(),
                    fileBasedConfiguration: FileBasedConfiguration(),
                    shutdownCallback: getShutdownCallback())
                )
                
                let credentials = try await provider.getCredentials()
                XCTAssertNotNil(credentials)
                assertCredentials(credentials: credentials)
            }
        }
        wait(for: [shutdownWasCalled], timeout: 15)
    }
    
    
    func testCreateDestroyCognitoCredsProviderWithoutHttpProxy() async throws {
        let exceptionWasThrown = XCTestExpectation(description: "Exception was thrown")
        do {
            let cognitoEndpoint = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_COGNITO_ENDPOINT")
            let cognitoIdentity = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_COGNITO_IDENTITY")
            
            
            let provider = try CredentialsProvider(source: .cognito(bootstrap: getClientBootstrap(), tlsContext: getTlsContext(), endpoint: cognitoEndpoint, identity: cognitoIdentity, shutdownCallback: getShutdownCallback()))
            let credentials = try await provider.getCredentials()
            XCTAssertNotNil(credentials)
        } catch {
            exceptionWasThrown.fulfill()
        }
        wait(for: [shutdownWasCalled], timeout: 15)
    }
    
    // Http proxy related tests could only run behind vpc to access the proxy
    func testCreateDestroyCognitoCredsProviderWithHttpProxy() async throws {
        let exceptionWasThrown = XCTestExpectation(description: "Exception was thrown")
        do {
            let cognitoEndpoint = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_COGNITO_ENDPOINT")
            let cognitoIdentity = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_COGNITO_IDENTITY")
            
            let httpproxyHost = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_HTTP_PROXY_HOST")
            let httpproxyPort = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_HTTP_PROXY_PORT")
            
            let httpProxys = HTTPProxyOptions(hostName: httpproxyHost, port: UInt32(httpproxyPort)!, connectionType: .tunnel)
            
            let provider = try CredentialsProvider(source: .cognito(bootstrap: getClientBootstrap(), tlsContext: getTlsContext(), endpoint: cognitoEndpoint, identity: cognitoIdentity, shutdownCallback: getShutdownCallback()))
            let credentials = try await provider.getCredentials()
            XCTAssertNotNil(credentials)
        } catch {
            exceptionWasThrown.fulfill()
        }
        wait(for: [shutdownWasCalled], timeout: 15)
    }
    
    func testCreateDestroyStsWebIdentityInvalidEnv() async throws {
        XCTAssertThrowsError(try CredentialsProvider(source: .stsWebIdentity(
            bootstrap: getClientBootstrap(),
            tlsContext: getTlsContext(),
            fileBasedConfiguration: FileBasedConfiguration()))
        )
    }
    
    func testCreateDestroyStsWebIdentity() async throws {
        _ = try! CredentialsProvider(source: .stsWebIdentity(
            bootstrap: getClientBootstrap(),
            tlsContext: getTlsContext(),
            fileBasedConfiguration: FileBasedConfiguration(),
            region: "region",
            roleArn: "roleArn",
            roleSessionName: "roleSessionName",
            tokenFilePath: "tokenFilePath"))
    }
    
    func testCreateDestroySts() async throws {
        let provider = try CredentialsProvider(source: .static(accessKey: accessKey,
                                                               secret: secret,
                                                               sessionToken: sessionToken))
        _ = try CredentialsProvider(source: .sts(bootstrap: getClientBootstrap(),
                                                 tlsContext: getTlsContext(),
                                                 credentialsProvider: provider,
                                                 roleArn: "roleArn",
                                                 sessionName: "test-session",
                                                 duration: 10,
                                                 shutdownCallback: getShutdownCallback()))
    }
    
    func testCreateDestroyEcsMissingCreds() async throws {
        let exceptionWasThrown = XCTestExpectation(description: "Exception was thrown")
        do {
            let provider = try CredentialsProvider(source: .ecs(bootstrap: getClientBootstrap(),
                                                                tlsContext: getTlsContext(),
                                                                authToken: "",
                                                                pathAndQuery: "",
                                                                host: "",
                                                                shutdownCallback: getShutdownCallback()))
            _ = try await provider.getCredentials()
        } catch {
            exceptionWasThrown.fulfill()
        }
        wait(for: [exceptionWasThrown], timeout: 15)
    }
    
}
