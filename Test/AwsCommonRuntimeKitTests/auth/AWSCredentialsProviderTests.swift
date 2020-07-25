//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit

class AWSCredentialsProviderTests: CrtXCBaseTestCase {
    let accessKey = "AccessKey"
    let secret = "Sekrit"
    let sessionToken = "Token"
    let shutDownOptions = CredentialsProviderShutdownOptions() {
        print("shut down")
    }
    func testCreateAWSCredentialsProviderStatic() {
        
        let config = CredentialsProviderStaticConfigOptions(accessKey: accessKey,
                                                            secret: secret,
                                                            sessionToken: sessionToken,
                                                            shutDownOptions: shutDownOptions)
        let provider = AWSCredentialsProvider(fromStatic: config, allocator: allocator)
        let callbackData = CredentialProviderCallbackData(provider: provider!) { (credentials, errorCode) in
            XCTAssertEqual(credentials.getAccessKey(), self.accessKey)
            XCTAssertNotNil(credentials)
            XCTAssertEqual(errorCode, 0)
        }
        provider?.getCredentials(credentialCallBackData: callbackData)
    }
    
    func testCreateAWSCredentialsProviderEnv() {
        _ = AWSCredentialsProvider(fromEnv: shutDownOptions)
    }
    
    func testCreateAWSCredentialsProviderProfile() {
        let config = CredentialsProviderProfileOptions(configFileNameOverride: "config",
                                                       profileFileNameOverride: "nicki",
                                                       credentialsFileNameOverride: "credentials",
                                                       shutdownOptions: shutDownOptions)
        _ = AWSCredentialsProvider(fromProfile: config)
    }
    
}


