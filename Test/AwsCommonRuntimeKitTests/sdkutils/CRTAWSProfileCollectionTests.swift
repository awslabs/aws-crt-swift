//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
import Foundation
@testable import AwsCommonRuntimeKit

class CRTAWSProfileCollectionTests: CrtXCBaseTestCase {
    func testGetPropertyFromBufferConfig() throws {
        let fakeConfig = "[default]\r\nregion=us-west-2".data(using: .utf8)!
        let buffer = ByteBuffer(data: fakeConfig)
        let profileCollection = try CRTAWSProfileCollection(fromBuffer: buffer, source: .config, allocator: allocator)
        let profile = profileCollection.getProfile(name: "default", allocator: allocator)
        let property = profile?.getProperty(name: "region", allocator: allocator)
        XCTAssertEqual("us-west-2", property?.value)
    }

    func testGetPropertyFromBufferCreds() throws {
        let fakeCreds = "[default]\r\naws_access_key_id=AccessKey\r\naws_secret_access_key=Sekrit".data(using: .utf8)!
        let buffer = ByteBuffer(data: fakeCreds)
        let profileCollection = try CRTAWSProfileCollection(fromBuffer: buffer, source: .credentials, allocator: allocator)
        let profile = profileCollection.getProfile(name: "default", allocator: allocator)!
        let property = profile.getProperty(name: "aws_access_key_id", allocator: allocator)!
        XCTAssertEqual("AccessKey", property.value)
    }

    func testGetProfileCollectionFromMerge() throws {
        let fakeConfig = "[default]\r\nregion=us-west-2".data(using: .utf8)!
        let configBuffer = ByteBuffer(data: fakeConfig)
        let profileCollectionConfig = try CRTAWSProfileCollection(fromBuffer: configBuffer, source: .config)

        let fakeCreds = "[default]\r\naws_access_key_id=AccessKey\r\naws_secret_access_key=Sekrit".data(using: .utf8)!
        let credBuffer = ByteBuffer(data: fakeCreds)
        let profileCollectionCreds = try CRTAWSProfileCollection(fromBuffer: credBuffer, source: .credentials, allocator: allocator)

        let mergedCollection = try CRTAWSProfileCollection(configProfileCollection: profileCollectionConfig, credentialProfileCollection: profileCollectionCreds)
        let profile = mergedCollection.getProfile(name: "default", allocator: allocator)!

        let accessKey = profile.getProperty(name: "aws_access_key_id")!
        XCTAssertEqual("AccessKey", accessKey.value)
        let region = profile.getProperty(name: "region", allocator: allocator)!
        XCTAssertEqual("us-west-2", region.value)
    }

    func testGetPropertyFromConfigFile() throws {
        let profileCollection = try CRTAWSProfileCollection(fromFile: Bundle.module.path(forResource: "example_profile", ofType: "txt")!, source: .credentials, allocator: allocator)
        let profile = profileCollection.getProfile(name: "default", allocator: allocator)!
        let property = profile.getProperty(name: "aws_access_key_id", allocator: allocator)!
        XCTAssertEqual("default_access_key_id", property.value)

        let s3Properties = profile.getProperty(name: "s3")!
        let subPropertyValue = s3Properties.getSubProperty(name: "max_concurrent_requests")!
        XCTAssertEqual("20", subPropertyValue)

        let crtUserProfile = profileCollection.getProfile(name: "crt_user", allocator: allocator)!
        let secretAccessKey = crtUserProfile.getProperty(name: "aws_secret_access_key")!
        XCTAssertEqual("example_secret_access_key", secretAccessKey.value)
    }

    func testCollectionOutOfScope() throws {
        var profile: CRTAWSProfile! = nil
        var crtUserProfile: CRTAWSProfile! = nil
        do{
            let profileCollection = try CRTAWSProfileCollection(fromFile: Bundle.module.path(forResource: "example_profile", ofType: "txt")!, source: .credentials, allocator: allocator)
            profile = profileCollection.getProfile(name: "default", allocator: allocator)!
            crtUserProfile = profileCollection.getProfile(name: "crt_user", allocator: allocator)!
        }
        let property = profile.getProperty(name: "aws_access_key_id", allocator: allocator)!
        XCTAssertEqual("default_access_key_id", property.value)

        let s3Properties = profile.getProperty(name: "s3")!
        let subPropertyValue = s3Properties.getSubProperty(name: "max_concurrent_requests")!
        XCTAssertEqual("20", subPropertyValue)

        let secretAccessKey = crtUserProfile.getProperty(name: "aws_secret_access_key")!
        XCTAssertEqual("example_secret_access_key", secretAccessKey.value)
    }
}
