//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
import Foundation
@testable import AwsCommonRuntimeKit

class FileBasedConfigurationTests: XCBaseTestCase {

    func testMergedCollectionFromPath() throws {
        let profilePath = Bundle.module.path(forResource: "example_profile", ofType: "txt")!
        let configPath = Bundle.module.path(forResource: "example_credentials", ofType: "txt")!
        let fileBasedConfiguration = try FileBasedConfiguration(configFilePath: profilePath, credentialsFilePath: configPath)
        XCTAssertNotNil(fileBasedConfiguration)
        let defaultSection = fileBasedConfiguration.getSection(name: "default", sectionType: .profile)!
        XCTAssertEqual(defaultSection.propertyCount, 4)
        let property = defaultSection.getProperty(name: "aws_access_key_id")!
        XCTAssertEqual("accessKey", property.value)

        let s3Properties = defaultSection.getProperty(name: "s3")!
        XCTAssertEqual(s3Properties.subPropertyCount, 1)
        let subPropertyValue = s3Properties.getSubProperty(name: "max_concurrent_requests")!
        XCTAssertEqual("20", subPropertyValue)

        let crtUserSection = fileBasedConfiguration.getSection(name: "crt_user", sectionType: .profile)!
        XCTAssertEqual(crtUserSection.propertyCount, 2)
        let secretAccessKey = crtUserSection.getProperty(name: "aws_secret_access_key")!
        XCTAssertEqual("example_secret_access_key", secretAccessKey.value)

        let credSection = fileBasedConfiguration.getSection(name: "credentials", sectionType: .profile)!
        XCTAssertEqual("accessKey1", credSection.getProperty(name: "aws_access_key_id")?.value)
        XCTAssertEqual(credSection.propertyCount, 2)

    }

    func testCollectionOutOfScope() throws {
        var defaultSection: FileBasedConfiguration.Section! = nil
        var crtUserSection: FileBasedConfiguration.Section! = nil
        do {
            let profilePath = Bundle.module.path(forResource: "example_profile", ofType: "txt")!
            let configPath = Bundle.module.path(forResource: "example_credentials", ofType: "txt")!
            let fileBasedConfiguration = try FileBasedConfiguration(configFilePath: profilePath, credentialsFilePath: configPath)
            defaultSection = fileBasedConfiguration.getSection(name: "default", sectionType: .profile)!
            crtUserSection = fileBasedConfiguration.getSection(name: "crt_user", sectionType: .profile)!
        }
        let property = defaultSection.getProperty(name: "aws_access_key_id")!
        XCTAssertEqual("accessKey", property.value)

        let s3Properties = defaultSection.getProperty(name: "s3")!
        let subPropertyValue = s3Properties.getSubProperty(name: "max_concurrent_requests")!
        XCTAssertEqual("20", subPropertyValue)

        let secretAccessKey = crtUserSection.getProperty(name: "aws_secret_access_key")!
        XCTAssertEqual("example_secret_access_key", secretAccessKey.value)
    }

    func testDefaultProfileName() throws {
        XCTAssertEqual(FileBasedConfiguration.defaultProfileName, "default")

        setenv("AWS_PROFILE", "", 1)
        XCTAssertEqual(FileBasedConfiguration.defaultProfileName, "")
        setenv("AWS_PROFILE", "profile", 1)
        XCTAssertEqual(FileBasedConfiguration.defaultProfileName, "profile")
        unsetenv("AWS_PROFILE")
    }

    func testResolveConfigPath() throws {
        // from $HOME
        let home = "/test/home"
        setenv("HOME", home, 1)
        XCTAssertEqual(try FileBasedConfiguration.resolveConfigPath(sourceType: .config), "\(home)/.aws/config")
        XCTAssertEqual(try FileBasedConfiguration.resolveConfigPath(sourceType: .credentials), "\(home)/.aws/credentials")

        // from environment
        setenv("AWS_CONFIG_FILE", "/environment/.aws/config", 1)
        setenv("AWS_SHARED_CREDENTIALS_FILE", "/environment/.aws/credentials", 1)
        XCTAssertEqual(try FileBasedConfiguration.resolveConfigPath(sourceType: .config), "/environment/.aws/config")
        XCTAssertEqual(try FileBasedConfiguration.resolveConfigPath(sourceType: .credentials), "/environment/.aws/credentials")

        // from absolute path
        XCTAssertEqual(try FileBasedConfiguration.resolveConfigPath(sourceType: .config, overridePath: "/path/.aws/config"), "/path/.aws/config")
        XCTAssertEqual(try FileBasedConfiguration.resolveConfigPath(sourceType: .credentials, overridePath: "/path/.aws/credentials"), "/path/.aws/credentials")

        // from relative path
        XCTAssertEqual(try FileBasedConfiguration.resolveConfigPath(sourceType: .config, overridePath: "~/.aws/config"), "\(home)/.aws/config")
        XCTAssertEqual(try FileBasedConfiguration.resolveConfigPath(sourceType: .credentials, overridePath: "~/.aws/credentials"), "\(home)/.aws/credentials")
    }
}
