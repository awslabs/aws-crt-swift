//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit

class AWSCredentialsProviderTests: CrtXCBaseTestCase {
    let accessKey = "AccessKey"
    let secret = "Sekrit"
    let sessionToken = "Token"
    let shutDownOptions = CredentialsProviderShutdownOptions() {
        XCTAssert(true)
    }
    let expectation = XCTestExpectation(description: "Credentials received")
    var callbackData: CredentialProviderCallbackData?
    
    func setUpCallbackCredentials(credentialsProvider: CredentialsProvider?){
        callbackData = CredentialProviderCallbackData(provider: credentialsProvider!, allocator: allocator) { (credentials, errorCode) in
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
        
        let config = CredentialsProviderProfileOptions(configFileNameOverride: "~/.aws/config",
                                                       profileFileNameOverride: "default",
                                                       credentialsFileNameOverride: "~/.aws/credentials",
                                                       shutdownOptions: shutDownOptions)
        let provider = AWSCredentialsProvider(fromProfile: config)

        setUpCallbackCredentials(credentialsProvider: provider)
        provider?.getCredentials(credentialCallBackData: callbackData!)
        wait(for: [expectation], timeout: 10.0)
    }
    

    
}




