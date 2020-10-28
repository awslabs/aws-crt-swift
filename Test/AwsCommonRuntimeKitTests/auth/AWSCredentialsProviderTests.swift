//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit

class AWSCredentialsProviderTests: CrtXCBaseTestCase {
    let accessKey = "AccessKey"
    let secret = "Sekrit"
    let sessionToken = "Token"

    let expectation = XCTestExpectation(description: "Credentials callback was called")
    let expectation2 = XCTestExpectation(description: "Shutdown callback was called")

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        if !name.contains("testCreateAWSCredentialsProviderProfile") {
        wait(for: [expectation2], timeout: 3.0)
        }
    }

    func setUpShutDownOptions() -> CredentialsProviderShutdownOptions {
        let shutDownOptions = CredentialsProviderShutdownOptions {
            XCTAssert(true)
            self.expectation2.fulfill()
        }
        return shutDownOptions
    }

    func setUpCallbackCredentials() -> CredentialsProviderCallbackData {
        let callbackData = CredentialsProviderCallbackData(allocator: allocator) { (_, errorCode) in

           //test that we got here successfully but not if we have credentials as we can't
           //test all uses cases i.e. some need to be on ec2 instance, etc
            XCTAssertNotNil(errorCode)
            self.expectation.fulfill()
        }
        return callbackData
    }

    func testCreateAWSCredentialsProviderStatic() {
        do {
        let shutDownOptions = setUpShutDownOptions()
        let config = CredentialsProviderStaticConfigOptions(accessKey: accessKey,
                                                            secret: secret,
                                                            sessionToken: sessionToken,
                                                            shutDownOptions: shutDownOptions)
        let provider = try AWSCredentialsProvider(fromStatic: config, allocator: allocator)
        let callbackData = setUpCallbackCredentials()
        provider.getCredentials(credentialCallbackData: callbackData)
        wait(for: [expectation], timeout: 5.0)
        } catch {
            XCTFail()
        }
    }

    func testCreateAWSCredentialsProviderEnv() {
        do {
        let shutDownOptions = setUpShutDownOptions()
        let provider = try AWSCredentialsProvider(fromEnv: shutDownOptions, allocator: allocator)
        let callbackData = setUpCallbackCredentials()
        provider.getCredentials(credentialCallbackData: callbackData)
        wait(for: [expectation], timeout: 5.0)
        } catch {
            XCTFail()
        }
    }

    func testCreateAWSCredentialsProviderProfile() throws {
        //skip this test if it is running on macosx or on iOS
        try skipIfiOS()
        try skipifmacOS()
        //uses default paths to credentials and config
        do {
        let shutDownOptions = setUpShutDownOptions()
        let config = CredentialsProviderProfileOptions(shutdownOptions: shutDownOptions)

        let provider = try AWSCredentialsProvider(fromProfile: config, allocator: allocator)

        let callbackData = setUpCallbackCredentials()
        provider.getCredentials(credentialCallbackData: callbackData)

        wait(for: [expectation], timeout: 5.0)
        } catch {
            XCTFail()
        }
    }

    func testCreateAWSCredentialsProviderChain() {
        do {
            let elgShutDownOptions = ShutDownCallbackOptions { semaphore in
                semaphore.signal()
            }

            let resolverShutDownOptions = ShutDownCallbackOptions { semaphore in
                semaphore.signal()
            }
            let elg = try EventLoopGroup(threadCount: 0, allocator: allocator, shutDownOptions: elgShutDownOptions)
            let hostResolver = try DefaultHostResolver(eventLoopGroup: elg,
                                                       maxHosts: 8,
                                                       maxTTL: 30,
                                                       allocator: allocator,
                                                       shutDownOptions: resolverShutDownOptions)

            let clientBootstrapCallbackData = ClientBootstrapCallbackData { sempahore in
                sempahore.signal()
            }
            let bootstrap = try ClientBootstrap(eventLoopGroup: elg,
                                                hostResolver: hostResolver,
                                                callbackData: clientBootstrapCallbackData,
                                                allocator: allocator)
            bootstrap.enableBlockingShutDown()
            let shutDownOptions = setUpShutDownOptions()

            let config = CredentialsProviderChainDefaultConfig(bootstrap: bootstrap, shutDownOptions: shutDownOptions)

            let provider = try AWSCredentialsProvider(fromChainDefault: config)
            let callbackData = setUpCallbackCredentials()
            provider.getCredentials(credentialCallbackData: callbackData)

            wait(for: [expectation], timeout: 10.0)
        } catch {
            XCTFail()
        }
    }
}
