//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
@testable import AwsCommonRuntimeKit

class CredentialsProviderTests: XCBaseTestCase {
    let accessKey = "AccessKey"
    let secret = "Sekrit"
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
        let elg = try EventLoopGroup(threadCount: 0, allocator: allocator)
        let hostResolver = try HostResolver(eventLoopGroup: elg,
                maxHosts: 8,
                maxTTL: 30,
                allocator: allocator)
        let bootstrap = try ClientBootstrap(eventLoopGroup: elg,
                hostResolver: hostResolver,
                allocator: allocator)
        return bootstrap
    }

    func getTlsContext() throws -> TLSContext {
        let options = TLSContextOptions(allocator: allocator)
        let context = try TLSContext(options: options, mode: .client, allocator: allocator)
        return context
    }

    func testDelegateCredentialsProvider() async throws {
        shutdownWasCalled.expectedFulfillmentCount = 2
        do {
            let staticProvider = try CredentialsProvider(source: .static(accessKey: accessKey,
                    secret: secret,
                    sessionToken: sessionToken,
                    shutdownCallback: getShutdownCallback()),
                    allocator: allocator)
            let delegateProvider = try CredentialsProvider(provider: staticProvider,
                    shutdownCallback: getShutdownCallback(),
                    allocator: allocator)
            let credentials = try await delegateProvider.getCredentials()
            XCTAssertNotNil(credentials)
            assertCredentials(credentials: credentials)
        }
        wait(for: [shutdownWasCalled], timeout: 15)
    }

    func testCreateCredentialsProviderStatic() async throws {
        do {
            let provider = try CredentialsProvider(source: .static(accessKey: accessKey,
                    secret: secret,
                    sessionToken: sessionToken,
                    shutdownCallback: getShutdownCallback()),
                    allocator: allocator)
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
                    configFileNameOverride: Bundle.module.path(forResource: "example_config", ofType: "txt")!,
                    credentialsFileNameOverride: Bundle.module.path(forResource: "example_profile", ofType: "txt")!,
                    shutdownCallback: getShutdownCallback()),
                    allocator: allocator)
            let credentials = try await provider.getCredentials()
            XCTAssertNotNil(credentials)
            XCTAssertEqual("default_access_key_id", credentials.getAccessKey())
            XCTAssertEqual("default_secret_access_key", credentials.getSecret())
        }
        wait(for: [shutdownWasCalled], timeout: 15)
    }

    func testCreateCredentialsProviderImds() async throws {
        do {
            _ = try CredentialsProvider(source: .imds(bootstrap: getClientBootstrap(),
                    shutdownCallback: getShutdownCallback()),
                    allocator: allocator)
        }
        wait(for: [shutdownWasCalled], timeout: 15)
    }

    func testCreateCredentialsProviderCache() async throws {
        do {
            let staticProvider = try CredentialsProvider(source: .static(accessKey: accessKey,
                    secret: secret,
                    sessionToken: sessionToken),
                    allocator: allocator)
            let cacheProvider = try CredentialsProvider(source: .cached(source: staticProvider,
                    shutdownCallback: getShutdownCallback()),
                    allocator: allocator)
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
                let provider = try CredentialsProvider(source: .defaultChain(bootstrap: getClientBootstrap(),
                        shutdownCallback: getShutdownCallback()),
                        allocator: allocator)

                let credentials = try await provider.getCredentials()
                XCTAssertNotNil(credentials)
                assertCredentials(credentials: credentials)
            }
        }
        wait(for: [shutdownWasCalled], timeout: 15)
    }

    func testCreateDestroyStsWebIdentityInvalidEnv() async throws {
        XCTAssertThrowsError(try CredentialsProvider(source: .stsWebIdentity(bootstrap: getClientBootstrap(),
                tlsContext: getTlsContext()),
                allocator: allocator))
    }

    func testCreateDestroyStsInvalidRole() async throws {
        let provider = try CredentialsProvider(source: .static(accessKey: accessKey,
                secret: secret,
                sessionToken: sessionToken))
        XCTAssertThrowsError(try CredentialsProvider(source: .sts(bootstrap: getClientBootstrap(),
                tlsContext: getTlsContext(),
                credentialsProvider: provider,
                roleArn: "invalid-role-arn",
                sessionName: "test-session",
                duration: 10,
                shutdownCallback: getShutdownCallback()),
                allocator: allocator))
    }

    func testCreateDestroyEcsMissingCreds() async throws {
        let exceptionWasThrown = XCTestExpectation(description: "Exception was thrown")
        do {
            let provider = try CredentialsProvider(source: .ecs(bootstrap: getClientBootstrap(),
                    tlsContext: getTlsContext(),
                    authToken: "",
                    pathAndQuery: "",
                    host: "",
                    shutdownCallback: getShutdownCallback()),
                    allocator: allocator)
            _ = try await provider.getCredentials()
        } catch {
            exceptionWasThrown.fulfill()
        }
        wait(for: [exceptionWasThrown], timeout: 15)
    }
}
