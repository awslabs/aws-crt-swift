//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCSdkUtils
import struct Foundation.Data

public class FileBasedConfiguration {
    var rawValue: OpaquePointer

    /// Create a FileBasedConfiguration by merging the configuration from config file and credentials file.
    /// - Parameters:
    ///   - configFilePath: (Optional) If a file path is provided use that, otherwise load config from the default config file.
    ///   - credentialsFilePath: (Optional) If a file path is provided use that, otherwise load config from the default config file.
    ///   - allocator: (Optional) allocator to override
    /// - Throws:
    public init(configFilePath: String? = nil,
                credentialsFilePath: String? = nil,
                allocator: Allocator = defaultAllocator) throws {
        // load file path for configuration files
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

        // load configuration collections
        let configCollection = aws_profile_collection_new_from_file(allocator.rawValue, configFilePath, FileBasedConfigSourceType.config.rawValue)
        defer {
            aws_profile_collection_release(configCollection)
        }

        let credentialsCollection = aws_profile_collection_new_from_file(allocator.rawValue, credentialsFilePath, FileBasedConfigSourceType.credentials.rawValue)
        defer {
            aws_profile_collection_release(credentialsCollection)
        }

        // merge the two collections
        guard let rawValue = aws_profile_collection_new_from_merge(allocator.rawValue,
                                                                   configCollection,
                                                                   credentialsCollection)
        else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        self.rawValue = rawValue
    }

    @available(*, deprecated, message: "Please use ")
    /// Create a new FileBasedConfiguration by parsing a file with the specified path
    public init(fromFile path: String,
                source: FileBasedConfigSourceType,
                allocator: Allocator = defaultAllocator) throws {
        var finalizedPath = path
        if path.hasPrefix("~"),
           let homeDirectory = aws_get_home_directory(allocator.rawValue),
           let homeDirectoryString = String(awsString: homeDirectory) {
            finalizedPath = homeDirectoryString + path.dropFirst()
        }
        let awsString = AWSString(finalizedPath, allocator: allocator)
        guard let profilePointer = aws_profile_collection_new_from_file(allocator.rawValue,
                                                                        awsString.rawValue,
                                                                        source.rawValue)
        else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        self.rawValue = profilePointer
    }

    /// Create a FileBasedConfiguration by parsing text in a buffer. Primarily for testing.
    init(fromData data: Data,
         source: FileBasedConfigSourceType,
         allocator: Allocator = defaultAllocator) throws {
        let byteCount = data.count
        guard let rawValue  = (data.withUnsafeBytes { rawBufferPointer -> OpaquePointer? in
            var byteBuf = aws_byte_buf_from_array(rawBufferPointer.baseAddress, byteCount)
            return aws_profile_collection_new_from_buffer(allocator.rawValue,
                                                          &byteBuf,
                                                          source.rawValue)
        }) else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        self.rawValue = rawValue
    }

    /// Create a FileBasedConfiguration by merging a config-file-based profile
    /// collection and a credentials-file-based profile collection
    public init(configProfileCollection: FileBasedConfiguration,
                credentialProfileCollection: FileBasedConfiguration,
                allocator: Allocator = defaultAllocator) throws {
        guard let rawValue = aws_profile_collection_new_from_merge(allocator.rawValue,
                                                                   configProfileCollection.rawValue,
                                                                   credentialProfileCollection.rawValue)
        else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        self.rawValue = rawValue
    }

    /// Retrieves a reference to a profile with the specified name, if it exists, from the profile collection
    ///
    /// - Parameters:
    ///   - name: The name of the section to retrieve
    ///   - sectionType: Type of section to retrieve
    ///   - allocator: (Optional) default allocator to override
    /// - Returns:
    public func getSection(name: String, sectionType: FileBasedConfigSectionType, allocator: Allocator = defaultAllocator) -> FileBasedConfigurationSection? {
        let awsString = AWSString(name, allocator: allocator)
        guard let profilePointer = aws_profile_collection_get_section(self.rawValue,
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
        aws_profile_collection_destroy(rawValue)
    }
}
