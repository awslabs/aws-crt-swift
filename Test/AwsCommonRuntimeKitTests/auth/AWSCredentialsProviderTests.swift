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
    var callbackData: CredentialProviderCallbackData?
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
        shutDownOptions = CredentialsProviderShutdownOptions() {
            XCTAssert(true)
            self.expectation2.fulfill()
        }
    }
    
    func setUpCallbackCredentials(credentialsProvider: CredentialsProvider?){
        callbackData = CredentialProviderCallbackData(allocator: allocator) { (credentials, errorCode) in
            
            XCTAssertNotNil(credentials)
            XCTAssertEqual(errorCode, 0)
            self.expectation.fulfill()
        }
    }
    
    func testCreateAWSCredentialsProviderStatic() {
    
        let config = CredentialsProviderStaticConfigOptions(accessKey: accessKey,
                                                            secret: secret,
                                                            sessionToken: sessionToken,
                                                            shutDownOptions: shutDownOptions)
        let provider = AWSCredentialsProvider(fromStatic: config, allocator: allocator)
        setUpCallbackCredentials(credentialsProvider: provider)
        provider?.getCredentials(credentialCallBackData: callbackData!)
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testCreateAWSCredentialsProviderEnv() {
    
        let provider = AWSCredentialsProvider(fromEnv: shutDownOptions)
        setUpCallbackCredentials(credentialsProvider: provider)
        provider?.getCredentials(credentialCallBackData: callbackData!)
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testCreateAWSCredentialsProviderProfile() {
        //uses default paths to credentials and config
        let config = CredentialsProviderProfileOptions(shutdownOptions: shutDownOptions)

        let provider = AWSCredentialsProvider(fromProfile: config)

        setUpCallbackCredentials(credentialsProvider: provider)
        provider?.getCredentials(credentialCallBackData: callbackData!)
        
        wait(for: [expectation], timeout: 5.0)
    }
    

    
}




