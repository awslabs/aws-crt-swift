//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit

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

    func testCreateAWSCredentialsProviderStatic() async throws {
        do {
            let config = MockCredentialsProviderStaticConfigOptions(accessKey: accessKey,
                    secret: secret,
                    sessionToken: sessionToken,
                    shutdownCallback: getShutdownCallback())
            let provider = try CRTAWSCredentialsProvider(fromStatic: config, allocator: allocator)
            let credentials = try await provider.getCredentials()
            XCTAssertNotNil(credentials)
        }
        wait(for: [shutdownWasCalled], timeout: 15)
    }

    func testCreateAWSCredentialsProviderEnv() async {
        do {
            let provider = try CRTAWSCredentialsProvider(fromEnv: getShutdownCallback(), allocator: allocator)
            _ = try await provider.getCredentials()

        } catch let err {
            let crtError = err as? CommonRunTimeError
            XCTAssertNotNil(crtError)
        }
        wait(for: [shutdownWasCalled], timeout: 15)
    }

    func testCreateAWSCredentialsProviderProfile() async throws {
        //skip this test if it is running on macosx or on iOS
        try skipIfiOS()
        try skipifmacOS()
        try skipIfLinux()
        //uses default paths to credentials and config
        do {
            let config = MockCredentialsProviderProfileOptions(shutdownCallback: getShutdownCallback())
            let provider = try CRTAWSCredentialsProvider(fromProfile: config, allocator: allocator)
            let credentials = try await provider.getCredentials()
            XCTAssertNotNil(credentials)
        }
        wait(for: [shutdownWasCalled], timeout: 15)
    }

    func testCreateAWSCredentialsProviderChain() async throws {
        try skipIfLinux()
        let elg = try EventLoopGroup(threadCount: 0, allocator: allocator)
        let hostResolver = try HostResolver(eventLoopGroup: elg,
                                               maxHosts: 8,
                                               maxTTL: 30,
                                               allocator: allocator)
        let bootstrap = try ClientBootstrap(eventLoopGroup: elg,
                                            hostResolver: hostResolver,
                                            allocator: allocator)
        do {
            let config = MockCredentialsProviderChainDefaultConfig(bootstrap: bootstrap, shutdownCallback: getShutdownCallback())
            let provider = try CRTAWSCredentialsProvider(fromChainDefault: config)

            let credentials = try await provider.getCredentials()
            XCTAssertNotNil(credentials)
        }
        wait(for: [shutdownWasCalled], timeout: 15)
    }

    func testCreateDestroyStsWebIdentityInvalidEnv() async throws {
        let elg = try EventLoopGroup(threadCount: 0, allocator: allocator)
        let hostResolver = try HostResolver(eventLoopGroup: elg,
                                               maxHosts: 8,
                                               maxTTL: 30,
                                               allocator: allocator)
        let bootstrap = try ClientBootstrap(eventLoopGroup: elg,
                                            hostResolver: hostResolver,
                                            allocator: allocator)
        let options = TlsContextOptions(defaultClientWithAllocator: allocator)
        let context = try TlsContext(options: options, mode: .client, allocator: allocator)
        let config = MockCredentialsProviderWebIdentityConfig(bootstrap: bootstrap, tlsContext: context)
        XCTAssertThrowsError(try CRTAWSCredentialsProvider(fromWebIdentity: config))
    }

    func testCreateDestroyStsInvalidRole() async throws {
        let elg = try EventLoopGroup(threadCount: 0, allocator: allocator)
        let hostResolver = try HostResolver(eventLoopGroup: elg,
                                               maxHosts: 8,
                                               maxTTL: 30,
                                               allocator: allocator)
        let bootstrap = try ClientBootstrap(eventLoopGroup: elg,
                                            hostResolver: hostResolver,
                                            allocator: allocator)
        let options = TlsContextOptions(defaultClientWithAllocator: allocator)
        let context = try TlsContext(options: options, mode: .client, allocator: allocator)
        let staticConfig = MockCredentialsProviderStaticConfigOptions(accessKey: accessKey,
                                                                      secret: secret,
                                                                      sessionToken: sessionToken)
        let provider = try CRTAWSCredentialsProvider(fromStatic: staticConfig, allocator: allocator)
        let config = MockCredentialsProviderSTSConfig(bootstrap: bootstrap,
                                                      tlsContext: context,
                                                      credentialsProvider: provider,
                                                      roleArn: "invalid-role-arn",
                                                      sessionName: "test-session",
                                                      durationSeconds: 10)
        XCTAssertThrowsError(try CRTAWSCredentialsProvider(fromSTS: config))
    }

    func testCreateDestroyEcsMissingCreds() async throws {
        let elg = try EventLoopGroup(threadCount: 0, allocator: allocator)
        let hostResolver = try HostResolver(eventLoopGroup: elg,
                                               maxHosts: 8,
                                               maxTTL: 30,
                                               allocator: allocator)
        do {
            let bootstrap = try ClientBootstrap(eventLoopGroup: elg,
                                                hostResolver: hostResolver,
                                                allocator: allocator)
                let options = TlsContextOptions(defaultClientWithAllocator: allocator)
            let context = try TlsContext(options: options, mode: .client, allocator: allocator)
            let config = MockCredentialsProviderContainerConfig(bootstrap: bootstrap,
                                                                tlsContext: context,
                                                                shutdownCallback: getShutdownCallback())
            let provider = try CRTAWSCredentialsProvider(fromContainer: config)
            let credentials = try await provider.getCredentials()
            XCTAssertNotNil(credentials)
        } catch let err {
            XCTAssertNotNil(err)
        }
        wait(for: [shutdownWasCalled], timeout: 15)
    }
}

struct MockCredentialsProviderProfileOptions: CRTCredentialsProviderProfileOptions {
    var shutdownCallback: ShutdownCallback?

    var configFileNameOverride: String?

    var profileFileNameOverride: String?

    var credentialsFileNameOverride: String?

    init(configFileNameOverride: String? = nil,
         profileFileNameOverride: String? = nil,
         credentialsFileNameOverride: String? = nil,
         shutdownCallback: ShutdownCallback? = nil) {
        self.configFileNameOverride = configFileNameOverride
        self.profileFileNameOverride = profileFileNameOverride
        self.credentialsFileNameOverride = credentialsFileNameOverride
        self.shutdownCallback = shutdownCallback
    }
}

struct MockCredentialsProviderStaticConfigOptions: CRTCredentialsProviderStaticConfigOptions {
    public var accessKey: String
    public var secret: String
    public var sessionToken: String?
    public var shutdownCallback: ShutdownCallback?

    public init(accessKey: String,
                secret: String,
                sessionToken: String? = nil,
                shutdownCallback: ShutdownCallback? = nil) {
        self.accessKey = accessKey
        self.secret = secret
        self.sessionToken = sessionToken
        self.shutdownCallback = shutdownCallback
    }
}

public struct MockCredentialsProviderChainDefaultConfig: CRTCredentialsProviderChainDefaultConfig {
    public var shutdownCallback: ShutdownCallback?
    public var bootstrap: ClientBootstrap

    public init(bootstrap: ClientBootstrap,
                shutdownCallback: ShutdownCallback? = nil) {
        self.bootstrap = bootstrap
        self.shutdownCallback = shutdownCallback
    }
}

struct MockCredentialsProviderWebIdentityConfig: CRTCredentialsProviderWebIdentityConfig {
    var shutdownCallback: ShutdownCallback?
    var bootstrap: ClientBootstrap
    var tlsContext: TlsContext

    init(bootstrap: ClientBootstrap,
         tlsContext: TlsContext,
         shutdownCallback: ShutdownCallback? = nil) {
        self.bootstrap = bootstrap
        self.tlsContext = tlsContext
        self.shutdownCallback = shutdownCallback
    }
}

struct MockCredentialsProviderSTSConfig: CRTCredentialsProviderSTSConfig {
    var shutdownCallback: ShutdownCallback?
    var bootstrap: ClientBootstrap
    var tlsContext: TlsContext
    var credentialsProvider: CRTAWSCredentialsProvider
    var roleArn: String
    var sessionName: String
    var durationSeconds: TimeInterval

    init(bootstrap: ClientBootstrap,
         tlsContext: TlsContext,
         credentialsProvider: CRTAWSCredentialsProvider,
         roleArn: String,
         sessionName: String,
         durationSeconds: TimeInterval,
         shutdownCallback: ShutdownCallback? = nil) {
        self.bootstrap = bootstrap
        self.tlsContext = tlsContext
        self.credentialsProvider = credentialsProvider
        self.roleArn = roleArn
        self.sessionName = sessionName
        self.durationSeconds = durationSeconds
        self.shutdownCallback = shutdownCallback
    }
}

struct MockCredentialsProviderContainerConfig: CRTCredentialsProviderContainerConfig {
    var shutdownCallback: ShutdownCallback?
    var bootstrap: ClientBootstrap
    var tlsContext: TlsContext
    var authToken: String?
    var pathAndQuery: String?
    var host: String?

    init(bootstrap: ClientBootstrap,
         tlsContext: TlsContext,
         authToken: String? = nil,
         pathAndQuery: String? = nil,
         host: String? = nil,
         shutdownCallback: ShutdownCallback? = nil) {
        self.bootstrap = bootstrap
        self.tlsContext = tlsContext
        self.authToken = authToken
        self.pathAndQuery = pathAndQuery
        self.host = host
        self.shutdownCallback = shutdownCallback
    }
}
