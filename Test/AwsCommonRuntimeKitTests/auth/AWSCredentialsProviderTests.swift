//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit

class AWSCredentialsProviderTests: CrtXCBaseTestCase {
    let accessKey = "AccessKey"
    let secret = "Sekrit"
    let sessionToken = "Token"

    let expectation = XCTestExpectation(description: "Credentials received")
    let expectation2 = XCTestExpectation(description: "Shutdown callback was called")
    var callbackData: CredentialsProviderCallbackData?
    var shutDownOptions: CredentialsProviderShutdownOptions?

    override func setUp() {
        super.setUp()
        setUpShutDownOptions()
    }

    override func tearDown() {
        super.tearDown()
        wait(for: [expectation2], timeout: 2.0)
    }

    func setUpShutDownOptions() {
        shutDownOptions = CredentialsProviderShutdownOptions {
            XCTAssert(true)
            self.expectation2.fulfill()
        }
    }

    func setUpCallbackCredentials() {
        callbackData = CredentialsProviderCallbackData(allocator: allocator) { (_, errorCode) in

           //test that we got here successfully but not if we have credentials as we can't
           //test all uses cases i.e. some need to be on ec2 instance, etc
            XCTAssertNotNil(errorCode)
            self.expectation.fulfill()
        }
    }

    func testCreateAWSCredentialsProviderStatic() {
        do {
        let config = CredentialsProviderStaticConfigOptions(accessKey: accessKey,
                                                            secret: secret,
                                                            sessionToken: sessionToken,
                                                            shutDownOptions: shutDownOptions)
        let provider = try AWSCredentialsProvider(fromStatic: config, allocator: allocator)
        setUpCallbackCredentials()
        provider.getCredentials(credentialCallbackData: callbackData!)
        wait(for: [expectation], timeout: 3.0)
        } catch {
            XCTFail()
        }
    }

    func testCreateAWSCredentialsProviderEnv() {
        do {
        let provider = try AWSCredentialsProvider(fromEnv: shutDownOptions)
        setUpCallbackCredentials()
        provider.getCredentials(credentialCallbackData: callbackData!)
        wait(for: [expectation], timeout: 3.0)
        } catch {
            XCTFail()
        }
    }

    func testCreateAWSCredentialsProviderProfile() {
        //uses default paths to credentials and config
        do {
        let config = CredentialsProviderProfileOptions(shutdownOptions: shutDownOptions)

        let provider = try AWSCredentialsProvider(fromProfile: config)

        setUpCallbackCredentials()
        provider.getCredentials(credentialCallbackData: callbackData!)

        wait(for: [expectation], timeout: 5.0)
        } catch {
            XCTFail()
        }
    }

    func testCreateAWSCredentialsProviderChain() {
        do {
            let elg = try EventLoopGroup(threadCount: 0, allocator: allocator)
            let hostResolver = try DefaultHostResolver(eventLoopGroup: elg, maxHosts: 8, maxTTL: 30, allocator: allocator)
            let bootstrap = try ClientBootstrap(eventLoopGroup: elg, hostResolver: hostResolver, allocator: allocator)
            bootstrap.enableBlockingShutDown()

            let config = CredentialsProviderChainDefaultConfig(bootstrap: bootstrap, shutDownOptions: shutDownOptions)

            let provider = try AWSCredentialsProvider(fromChainDefault: config)
            setUpCallbackCredentials()
            provider.getCredentials(credentialCallbackData: callbackData!)

            wait(for: [expectation], timeout: 3.0)
        } catch {
            XCTFail()
        }
    }
}
