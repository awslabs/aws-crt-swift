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

    func testCreateCredentialsProviderStatic() async throws {
        do {
            let provider = try CredentialsProvider.makeStatic(accessKey: accessKey,
                                                                    secret: secret,
                                                                    sessionToken: sessionToken,
                                                                    shutdownCallback: getShutdownCallback())
            let credentials = try await provider.getCredentials()
            XCTAssertNotNil(credentials)
        }
        wait(for: [shutdownWasCalled], timeout: 15)
    }

    //TODO: fix
    func testCreateCredentialsProviderEnv() async {
        do {
            let provider = try CredentialsProvider.makeEnvironment(shutdownCallback: getShutdownCallback(), allocator: allocator)
            _ = try await provider.getCredentials()

        } catch let err {
            let crtError = err as? CommonRunTimeError
            XCTAssertNotNil(crtError)
        }
        wait(for: [shutdownWasCalled], timeout: 15)
    }

    func testCreateCredentialsProviderProfile() async throws {
        //skip this test if it is running on macosx or on iOS
        try skipIfiOS()
        try skipifmacOS()
        try skipIfLinux()
        //uses default paths to credentials and config
        do {
            let provider = try CredentialsProvider.makeProfile(shutdownCallback: getShutdownCallback(), allocator: allocator)
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
            let provider = try CredentialsProvider.makeDefaultChain(bootstrap: bootstrap,
                                                                  shutdownCallback: getShutdownCallback(),
                                                                  allocator: allocator)

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
        let options = TlsContextOptions(allocator: allocator)
        let context = try TlsContext(options: options, mode: .client, allocator: allocator)
        XCTAssertThrowsError(try CredentialsProvider.makeWebIdentity(bootstrap: bootstrap, tlsContext: context, allocator: allocator))
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
        let options = TlsContextOptions(allocator: allocator)
        let context = try TlsContext(options: options, mode: .client, allocator: allocator)
        let provider = try CredentialsProvider.makeStatic(accessKey: accessKey,
                                                                secret: secret,
                                                                sessionToken: sessionToken)
        XCTAssertThrowsError(try CredentialsProvider.makeSTS(bootstrap: bootstrap,
                                                             tlsContext: context,
                                                             credentialsProvider: provider,
                                                             roleArn: "invalid-role-arn",
                                                             sessionName: "test-session",
                                                             duration: 10,
                                                             allocator: allocator))
    }

// TODO: default values for host
//    func testCreateDestroyEcsMissingCreds() async throws {
//        let elg = try EventLoopGroup(threadCount: 0, allocator: allocator)
//        let hostResolver = try HostResolver(eventLoopGroup: elg,
//                                               maxHosts: 8,
//                                               maxTTL: 30,
//                                               allocator: allocator)
//        do {
//            let bootstrap = try ClientBootstrap(eventLoopGroup: elg,
//                                                hostResolver: hostResolver,
//                                                allocator: allocator)
//                let options = TlsContextOptions(allocator: allocator)
//            let context = try TlsContext(options: options, mode: .client, allocator: allocator)
//            let provider = try CredentialsProvider.makeContainer(bootstrap: bootstrap,
//                                                                 tlsContext: context,
//                                                                 shutdownCallback: getShutdownCallback(),
//                                                                 allocator: allocator)
//            let credentials = try await provider.getCredentials()
//            XCTAssertNotNil(credentials)
//        } catch let err {
//            XCTAssertNotNil(err)
//        }
//        wait(for: [shutdownWasCalled], timeout: 15)
//    }
}