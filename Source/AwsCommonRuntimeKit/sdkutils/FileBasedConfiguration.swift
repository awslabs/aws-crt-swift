//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCSdkUtils
import struct Foundation.Data

public class FileBasedConfiguration {
    var rawValue: OpaquePointer

    /// Create a FileBasedConfiguration by merging the configuration from config file and credentials file.
    /// - Parameters:
    ///   - configFilePath: (Optional) If a file path is provided use that, otherwise loads config from the default location (~/.aws/config).
    ///   - credentialsFilePath: (Optional) If a file path is provided use that, otherwise loads config from the default location (~/.aws/credentials)
    ///   - allocator: (Optional) allocator to override
    /// - Throws: CommonRuntimeError.crtError
    public init(configFilePath: String? = nil,
                credentialsFilePath: String? = nil,
                allocator: Allocator = defaultAllocator) throws {
        guard let credentialsFilePath = withOptionalByteCursorPointerFromString(credentialsFilePath, {
            aws_get_credentials_file_path(allocator.rawValue, $0)
        })
        else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        defer {
            aws_string_destroy(credentialsFilePath)
        }

        guard let configFilePath = withOptionalByteCursorPointerFromString(configFilePath, {
            aws_get_config_file_path(allocator.rawValue, $0)
        })
        else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        defer {
            aws_string_destroy(configFilePath)
        }

        let configCollection = aws_profile_collection_new_from_file(
            allocator.rawValue,
            configFilePath,
            AWS_PST_CONFIG)
        defer {
            aws_profile_collection_release(configCollection)
        }

        let credentialsCollection = aws_profile_collection_new_from_file(
            allocator.rawValue,
            credentialsFilePath,
            AWS_PST_CREDENTIALS)
        defer {
            aws_profile_collection_release(credentialsCollection)
        }

        // merge the two configurations
        guard let rawValue = aws_profile_collection_new_from_merge(
                allocator.rawValue,
                configCollection,
                credentialsCollection)
        else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        self.rawValue = rawValue
    }

    /// Retrieves a reference to a section with the specified name, if it exists.
    ///
    /// - Parameters:
    ///   - name: The name of the section to retrieve
    ///   - sectionType: Type of section to retrieve
    ///   - allocator: (Optional) default allocator to override
    /// - Returns: FileBasedConfigurationSection if it exists.
    public func getSection(
        name: String,
        sectionType: FileBasedConfigSectionType,
        allocator: Allocator = defaultAllocator) -> FileBasedConfigurationSection? {

        let awsString = AWSString(name, allocator: allocator)
        guard let profilePointer = aws_profile_collection_get_section(
                self.rawValue,
                sectionType.rawValue,
                awsString.rawValue)
        else {
            return nil
        }
        return FileBasedConfigurationSection(rawValue: profilePointer, collection: self)
    }

    /// Returns how many sections a collection holds
    public var profileCount: Int {
        return aws_profile_collection_get_profile_count(rawValue)
    }

    deinit {
        aws_profile_collection_release(rawValue)
    }
}
