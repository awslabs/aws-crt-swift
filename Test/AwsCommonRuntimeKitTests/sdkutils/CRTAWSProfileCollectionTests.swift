//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
import Foundation
@testable import AwsCommonRuntimeKit

class CRTAWSProfileCollectionTests: CrtXCBaseTestCase {
    func testGetPropertyFromBufferConfig() {
        let fakeConfig = "[default]\r\nregion=us-west-2".data(using: .utf8)!
        let buffer = ByteBuffer(data: fakeConfig)
        let profileCollection = CRTAWSProfileCollection(fromBuffer: buffer, source: .config, allocator: allocator)
        XCTAssertNotNil(profileCollection)
        let profile = profileCollection.getProfile(name: "default", allocator: allocator)
        let property = profile?.getProperty(name: "region", allocator: allocator)
        XCTAssertEqual("us-west-2", property?.value)
    }
    
    func testGetPropertyFromBufferCreds() {
        let fakeCreds = "[default]\r\naws_access_key_id=AccessKey\r\naws_secret_access_key=Sekrit".data(using: .utf8)!
        let buffer = ByteBuffer(data: fakeCreds)
        let profileCollection = CRTAWSProfileCollection(fromBuffer: buffer, source: .credentials, allocator: allocator)
        XCTAssertNotNil(profileCollection)
        let profile = profileCollection.getProfile(name: "default", allocator: allocator)
        let property = profile?.getProperty(name: "aws_access_key_id", allocator: allocator)
        XCTAssertEqual("AccessKey", property?.value)
    }
    
    func testGetProfileCollectionFromMerge() {
        let fakeConfig = "[default]\r\nregion=us-west-2".data(using: .utf8)!
        let configBuffer = ByteBuffer(data: fakeConfig)
        let profileCollectionConfig = CRTAWSProfileCollection(fromBuffer: configBuffer, source: .config)
        
        let fakeCreds = "[default]\r\naws_access_key_id=AccessKey\r\naws_secret_access_key=Sekrit".data(using: .utf8)!
        let credBuffer = ByteBuffer(data: fakeCreds)
        let profileCollectionCreds = CRTAWSProfileCollection(fromBuffer: credBuffer, source: .credentials, allocator: allocator)
        
        let mergedCollection = CRTAWSProfileCollection(configProfileCollection: profileCollectionConfig, credentialProfileCollection: profileCollectionCreds, source: .credentials)
        XCTAssertNotNil(mergedCollection)
        let profile = mergedCollection?.getProfile(name: "default", allocator: allocator)

        let accessKey = profile?.getProperty(name: "aws_access_key_id")
        XCTAssertEqual("AccessKey", accessKey?.value)
        let region = profile?.getProperty(name: "region", allocator: allocator)
        XCTAssertEqual("us-west-2", region?.value)
    }

    func testGetPropertyFromConfigFile() {
        let profileCollection = CRTAWSProfileCollection(fromFile: Bundle.module.path(forResource: "example_profile", ofType: "txt")!, source: .credentials, allocator: allocator)
        let profile = profileCollection?.getProfile(name: "default", allocator: allocator)
        let property = profile?.getProperty(name: "aws_access_key_id", allocator: allocator)
        XCTAssertEqual("default_access_key_id", property?.value)

        let crtUserProfile = profileCollection?.getProfile(name: "crt_user", allocator: allocator)
        let secretAccessKey = crtUserProfile?.getProperty(name: "aws_secret_access_key")
        XCTAssertEqual("example_secret_access_key", secretAccessKey?.value)
    }
}
