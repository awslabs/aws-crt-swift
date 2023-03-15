//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
import Foundation
@testable import AwsCommonRuntimeKit

class FileBasedConfigurationTests: XCBaseTestCase {
    func testGetPropertyFromBufferConfig() throws {
        let fakeConfig = "[default]\r\nregion=us-west-2".data(using: .utf8)!
        let fileBasedConfiguration = try FileBasedConfiguration(fromData: fakeConfig, source: .config, allocator: allocator)
        let section = fileBasedConfiguration.getSection(name: "default", sectionType: FileBasedConfigSectionType.profile, allocator: allocator)
        let property = section?.getProperty(name: "region", allocator: allocator)
        XCTAssertEqual("us-west-2", property?.value)
    }

    func testGetPropertyFromBufferCreds() throws {
        let fakeCreds = "[default]\r\naws_access_key_id=AccessKey\r\naws_secret_access_key=Sekrit".data(using: .utf8)!
        let fileBasedConfiguration = try FileBasedConfiguration(fromData: fakeCreds, source: .credentials, allocator: allocator)
        let profile = fileBasedConfiguration.getSection(name: "default", sectionType: FileBasedConfigSectionType.profile, allocator: allocator)!
        let property = profile.getProperty(name: "aws_access_key_id", allocator: allocator)!
        XCTAssertEqual("AccessKey", property.value)
    }

    func testGetProfileCollectionFromMerge() throws {
        let fakeConfig = "[default]\r\nregion=us-west-2".data(using: .utf8)!
        let profileFileBasedConfiguration = try FileBasedConfiguration(fromData: fakeConfig, source: .config)

        let fakeCreds = "[default]\r\naws_access_key_id=AccessKey\r\naws_secret_access_key=Sekrit".data(using: .utf8)!
        let credentialsFileBasedConfiguration = try FileBasedConfiguration(fromData: fakeCreds, source: .credentials, allocator: allocator)

        let mergedCollection = try FileBasedConfiguration(configProfileCollection: profileFileBasedConfiguration, credentialProfileCollection: credentialsFileBasedConfiguration)
        let profile = mergedCollection.getSection(name: "default", sectionType: FileBasedConfigSectionType.profile, allocator: allocator)!

        let accessKey = profile.getProperty(name: "aws_access_key_id")!
        XCTAssertEqual("AccessKey", accessKey.value)
        let region = profile.getProperty(name: "region", allocator: allocator)!
        XCTAssertEqual("us-west-2", region.value)
    }

    func testGetPropertyFromConfigFile() throws {
        let fileBasedConfiguration = try FileBasedConfiguration(fromFile: Bundle.module.path(forResource: "example_profile", ofType: "txt")!, source: .config, allocator: allocator)
        let profile = fileBasedConfiguration.getSection(name: "default", sectionType: FileBasedConfigSectionType.profile, allocator: allocator)!
        let property = profile.getProperty(name: "aws_access_key_id", allocator: allocator)!
        XCTAssertEqual("default_access_key_id", property.value)

        let s3Properties = profile.getProperty(name: "s3")!
        let subPropertyValue = s3Properties.getSubProperty(name: "max_concurrent_requests")!
        XCTAssertEqual("20", subPropertyValue)

        let crtUserProfile = fileBasedConfiguration.getSection(name: "crt_user", sectionType: FileBasedConfigSectionType.profile, allocator: allocator)!
        let secretAccessKey = crtUserProfile.getProperty(name: "aws_secret_access_key")!
        XCTAssertEqual("example_secret_access_key", secretAccessKey.value)
    }

    func testMergedCollectionFromPath() throws {
        let profilePath = Bundle.module.path(forResource: "example_profile", ofType: "txt")!
        let configPath = Bundle.module.path(forResource: "example_credentials", ofType: "txt")!
        let fileBasedConfiguration = try FileBasedConfiguration(configFilePath: profilePath, credentialsFilePath: configPath, allocator: allocator)
        XCTAssertNotNil(fileBasedConfiguration)
        let profile = fileBasedConfiguration.getSection(name: "default", sectionType: FileBasedConfigSectionType.profile, allocator: allocator)!
        let property = profile.getProperty(name: "aws_access_key_id", allocator: allocator)!
        XCTAssertEqual("accessKey", property.value)

        let s3Properties = profile.getProperty(name: "s3")!
        let subPropertyValue = s3Properties.getSubProperty(name: "max_concurrent_requests")!
        XCTAssertEqual("20", subPropertyValue)

        let crtUserProfile = fileBasedConfiguration.getSection(name: "crt_user", sectionType: FileBasedConfigSectionType.profile, allocator: allocator)!
        let secretAccessKey = crtUserProfile.getProperty(name: "aws_secret_access_key")!
        XCTAssertEqual("example_secret_access_key", secretAccessKey.value)

        let credProfile = fileBasedConfiguration.getSection(name: "credentials", sectionType: FileBasedConfigSectionType.profile)!
        XCTAssertEqual("accessKey1", credProfile.getProperty(name: "aws_access_key_id")?.value)
    }

    func testCollectionOutOfScope() throws {
        var profile: FileBasedConfigurationSection! = nil
        var crtUserProfile: FileBasedConfigurationSection! = nil
        do{
            let fileBasedConfiguration = try FileBasedConfiguration(fromFile: Bundle.module.path(forResource: "example_profile", ofType: "txt")!, source: .config, allocator: allocator)
            profile = fileBasedConfiguration.getSection(name: "default", sectionType: FileBasedConfigSectionType.profile, allocator: allocator)!
            crtUserProfile = fileBasedConfiguration.getSection(name: "crt_user", sectionType: FileBasedConfigSectionType.profile, allocator: allocator)!
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
