//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
import Foundation
@testable import AwsCommonRuntimeKit

class ProfileCollectionTests: XCBaseTestCase {
    func testGetPropertyFromBufferConfig() throws {
        let fakeConfig = "[default]\r\nregion=us-west-2".data(using: .utf8)!
        let profileCollection = try ProfileCollection(fromData: fakeConfig, source: .config, allocator: allocator)
        let profile = profileCollection.getProfile(name: "default", allocator: allocator)
        let property = profile?.getProperty(name: "region", allocator: allocator)
        XCTAssertEqual("us-west-2", property?.value)
    }

    func testGetPropertyFromBufferCreds() throws {
        let fakeCreds = "[default]\r\naws_access_key_id=AccessKey\r\naws_secret_access_key=Sekrit".data(using: .utf8)!
        let profileCollection = try ProfileCollection(fromData: fakeCreds, source: .credentials, allocator: allocator)
        let profile = profileCollection.getProfile(name: "default", allocator: allocator)!
        let property = profile.getProperty(name: "aws_access_key_id", allocator: allocator)!
        XCTAssertEqual("AccessKey", property.value)
    }

    func testGetProfileCollectionFromMerge() throws {
        let fakeConfig = "[default]\r\nregion=us-west-2".data(using: .utf8)!
        let profileCollectionConfig = try ProfileCollection(fromData: fakeConfig, source: .config)

        let fakeCreds = "[default]\r\naws_access_key_id=AccessKey\r\naws_secret_access_key=Sekrit".data(using: .utf8)!
        let profileCollectionCreds = try ProfileCollection(fromData: fakeCreds, source: .credentials, allocator: allocator)

        let mergedCollection = try ProfileCollection(configProfileCollection: profileCollectionConfig, credentialProfileCollection: profileCollectionCreds)
        let profile = mergedCollection.getProfile(name: "default", allocator: allocator)!

        let accessKey = profile.getProperty(name: "aws_access_key_id")!
        XCTAssertEqual("AccessKey", accessKey.value)
        let region = profile.getProperty(name: "region", allocator: allocator)!
        XCTAssertEqual("us-west-2", region.value)
    }

    func testGetPropertyFromConfigFile() throws {
        let profileCollection = try ProfileCollection(fromFile: Bundle.module.path(forResource: "example_profile", ofType: "txt")!, source: .credentials, allocator: allocator)
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
        var profile: Profile! = nil
        var crtUserProfile: Profile! = nil
        do{
            let profileCollection = try ProfileCollection(fromFile: Bundle.module.path(forResource: "example_profile", ofType: "txt")!, source: .credentials, allocator: allocator)
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
