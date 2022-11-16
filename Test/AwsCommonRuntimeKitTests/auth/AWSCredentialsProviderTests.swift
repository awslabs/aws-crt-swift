//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit

//TODO: rename file
class AWSCredentialsProviderTests: CrtXCBaseTestCase {
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
        return  {
            self.shutdownWasCalled.fulfill()
        }
    }

    func assertCredentials(credentials: AwsCredentials) {
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

    func getTlsContext() throws -> TlsContext {
        let options = TlsContextOptions(allocator: allocator)
        let context = try TlsContext(options: options, mode: .client, allocator: allocator)
        return context
    }

    func testDelegateCredentialsProvider() async throws {
        shutdownWasCalled.expectedFulfillmentCount = 2
        do {
            let staticProvider = try AwsCredentialsProvider.makeStatic(accessKey: accessKey,
                                                                       secret: secret,
                                                                       sessionToken: sessionToken,
                                                                       shutdownCallback: getShutdownCallback(),
                                                                       allocator: allocator)

            let delegateProvider = try AwsCredentialsProvider.makeDelegate(credentialsProvider: staticProvider,
                                                                           allocator: allocator,
                                                                           shutdownCallback: getShutdownCallback())
            let credentials = try await delegateProvider.getCredentials()
            XCTAssertNotNil(credentials)
            assertCredentials(credentials: credentials)
        }
        wait(for: [shutdownWasCalled], timeout: 15)
    }

    func testCreateCredentialsProviderStatic() async throws {
        do {
            let provider = try AwsCredentialsProvider.makeStatic(accessKey: accessKey,
                                                              secret: secret,
                                                              sessionToken: sessionToken,
                                                              shutdownCallback: getShutdownCallback(),
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
            let provider = try AwsCredentialsProvider.makeEnvironment()
            _ = try await provider.getCredentials()
        } catch {
           exceptionWasThrown.fulfill()
        }
        wait(for: [exceptionWasThrown], timeout: 15)
    }

    func testCreateCredentialsProviderEnv() async throws {
        setenv("AWS_ACCESS_KEY_ID", accessKey, 1)
        setenv("AWS_SECRET_ACCESS_KEY", secret, 1)
        setenv("AWS_SESSION_TOKEN", sessionToken, 1)
        defer {
            unsetenv("AWS_ACCESS_KEY_ID")
            unsetenv("AWS_SECRET_ACCESS_KEY")
            unsetenv("AWS_SESSION_TOKEN")
        }
        let provider = try AwsCredentialsProvider.makeEnvironment()
        let credentials = try await provider.getCredentials()
        assertCredentials(credentials: credentials)

    }

    func testCreateCredentialsProviderProfile() async throws {
        do {

            let provider = try AwsCredentialsProvider.makeProfile(configFileNameOverride:  Bundle.module.path(forResource: "example_config", ofType: "txt")!,
                    credentialsFileNameOverride: Bundle.module.path(forResource: "example_profile", ofType: "txt")!,
                                                               shutdownCallback: getShutdownCallback(),
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
            _ = try AwsCredentialsProvider.makeImds(bootstrap: getClientBootstrap(),
                                                 shutdownCallback: getShutdownCallback(),
                                                 allocator: allocator)
        }
        wait(for: [shutdownWasCalled], timeout: 15)
    }

    func testCreateCredentialsProviderCache() async throws {
        do {
            let staticProvider = try AwsCredentialsProvider.makeStatic(accessKey: accessKey,
                    secret: secret,
                    sessionToken: sessionToken,
                    allocator: allocator)
            let cacheProvider = try AwsCredentialsProvider.makeCached(source: staticProvider,
                                                                   shutdownCallback: getShutdownCallback(),
                                                                   allocator: allocator)
            let credentials = try await cacheProvider.getCredentials()
            XCTAssertNotNil(credentials)
            assertCredentials(credentials: credentials)
        }
        wait(for: [shutdownWasCalled], timeout: 15)
    }

    func testCreateAWSCredentialsProviderChain() async throws {
        try skipIfLinux()
        do {
            let provider = try AwsCredentialsProvider.makeDefaultChain(bootstrap: getClientBootstrap(),
                                                                    shutdownCallback: getShutdownCallback(),
                                                                    allocator: allocator)

            let credentials = try await provider.getCredentials()
            XCTAssertNotNil(credentials)
        }
        wait(for: [shutdownWasCalled], timeout: 15)
    }

    func testCreateDestroyStsWebIdentityInvalidEnv() async throws {
        XCTAssertThrowsError(try AwsCredentialsProvider.makeSTSWebIdentity(bootstrap: getClientBootstrap(),
                                                                        tlsContext: getTlsContext(),
                                                                        allocator: allocator))
    }

    func testCreateDestroyStsInvalidRole() async throws {
        let provider = try AwsCredentialsProvider.makeStatic(accessKey: accessKey,
                                                          secret: secret,
                                                          sessionToken: sessionToken)
        XCTAssertThrowsError(try AwsCredentialsProvider.makeSTS(bootstrap: getClientBootstrap(),
                                                             tlsContext: getTlsContext(),
                                                             credentialsProvider: provider,
                                                             roleArn: "invalid-role-arn",
                                                             sessionName: "test-session",
                                                             duration: 10,
                                                             allocator: allocator))
    }

    func testCreateDestroyEcsMissingCreds() async throws {
        let exceptionWasThrown = XCTestExpectation(description: "Exception was thrown")
        do {
            let provider = try AwsCredentialsProvider.makeECS(bootstrap: getClientBootstrap(),
                                                           tlsContext: getTlsContext(),
                                                           authToken: "",
                                                           pathAndQuery: "",
                                                           host: "",
                                                           shutdownCallback: getShutdownCallback(),
                                                           allocator: allocator)
            _ = try await provider.getCredentials()
        } catch {
            exceptionWasThrown.fulfill()
        }
        wait(for: [exceptionWasThrown], timeout: 15)
    }
}
