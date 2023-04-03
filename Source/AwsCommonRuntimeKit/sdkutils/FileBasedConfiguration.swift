//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCSdkUtils
import struct Foundation.Data

public class FileBasedConfiguration {
    var rawValue: OpaquePointer

    /// If the `AWS_PROFILE` environment variable is set, use it. Otherwise, return "default".
    public static var defaultProfileName: String {
        let profileName = aws_get_profile_name(allocator.rawValue, nil)!
        defer {
            aws_string_destroy(profileName)
        }
        return String(awsString: profileName)!
    }

    /// Create a FileBasedConfiguration by merging the configuration from config file and credentials file.
    /// - Parameters:
    ///   - configFilePath: (Optional) If a file path is provided, use that. Otherwise, if the `AWS_CONFIG_FILE` environment variable is set, load the path from it;
    ///                     if not, load the config from the default location (~/.aws/config).
    ///   - credentialsFilePath: (Optional) If a file path is provided, use that. Otherwise, if the `AWS_SHARED_CREDENTIALS_FILE` environment variable is set, load the path from it;
    ///                          if not, load the config from the default location (~/.aws/credentials).
    /// - Throws: CommonRuntimeError.crtError
    public init(
        configFilePath: String? = nil,
        credentialsFilePath: String? = nil
    ) throws {
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

    /// If a file path is provided, use that. Otherwise, there are a few options:
    /// - If the source type is config, check if the `AWS_CONFIG_FILE environment` variable is set.
    ///   If it is, load the path from it. If not, load the config from the default location ~/.aws/config.
    /// - If the source type is credentials, check if the `AWS_SHARED_CREDENTIALS_FILE` environment variable is set.
    ///   If it is, load the path from it. If not, load the credentials from the default location ~/.aws/credentials.
    /// - Parameters:
    ///   - sourceType: The type of source file
    ///   - overridePath: (Optional) path to override. If provided, it will do limited home directory expansion/resolution.
    /// - Returns: Resolved path
    /// - Throws: CommonRuntimeError.crtError
    public static func resolveConfigPath(
        sourceType: SourceType,
        overridePath: String? = nil
    ) throws -> String {
        guard let filePath: UnsafeMutablePointer<aws_string> = withOptionalByteCursorPointerFromString(
                overridePath, { path in
                    switch sourceType {
                    case .config:  return aws_get_config_file_path(allocator.rawValue, path)
                    case .credentials: return aws_get_credentials_file_path(allocator.rawValue, path)
                    }
                }) else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        defer {
            aws_string_destroy(filePath)
        }

        return String(awsString: filePath)!
    }

    /// Retrieves a reference to a section with the specified name, if it exists.
    /// - Parameters:
    ///   - name: The name of the section to retrieve
    ///   - sectionType: Type of section to retrieve
    /// - Returns: FileBasedConfiguration.Section if it exists.
    public func getSection(
        name: String,
        sectionType: SectionType
    ) -> Section? {
        let awsString = AWSString(name)
        guard let sectionPointer = aws_profile_collection_get_section(
                self.rawValue,
                sectionType.rawValue,
                awsString.rawValue)
        else {
            return nil
        }
        return Section(rawValue: sectionPointer, fileBasedConfiguration: self)
    }

    deinit {
        aws_profile_collection_release(rawValue)
    }
}

extension FileBasedConfiguration {

    /// Type of section in a config file
    public enum SectionType {
        case profile
        case ssoSession
    }

    /// Source of file based config
    public enum SourceType {
        case config
        case credentials
    }

    /// Represents a section in the FileBasedConfiguration
    public class Section {
        let rawValue: OpaquePointer
        // Keep a reference of configuration to keep it alive
        let fileBasedConfiguration: FileBasedConfiguration

        init(rawValue: OpaquePointer, fileBasedConfiguration: FileBasedConfiguration) {
            self.rawValue = rawValue
            self.fileBasedConfiguration = fileBasedConfiguration
        }

        /// Returns a reference to the name of the provided profile
        public var name: String {
            String(awsString: aws_profile_get_name(rawValue))!
        }

        /// Retrieves a reference to a property with the specified name, if it exists, from a profile
        /// - Parameters:
        ///   - name: The name of property to retrieve
        /// - Returns: A reference to a property with the specified name, if it exists, from a profile
        public func getProperty(
            name: String
        ) -> FileBasedConfiguration.Section.Property? {
            let nameAwsString = AWSString(name)
            guard let propPointer = aws_profile_get_property(rawValue, nameAwsString.rawValue) else {
                return nil
            }
            return FileBasedConfiguration.Section.Property(
                rawValue: propPointer,
                fileBasedConfiguration: fileBasedConfiguration)
        }

        /// Returns how many properties a section holds
        public var propertyCount: Int {
            aws_profile_get_property_count(rawValue)
        }
    }

}

extension FileBasedConfiguration.SourceType {
    var rawValue: aws_profile_source_type {
        switch self {
        case .config: return AWS_PST_CONFIG
        case .credentials: return AWS_PST_CREDENTIALS
        }
    }
}

extension FileBasedConfiguration.SectionType {
    var rawValue: aws_profile_section_type {
        switch self {
        case .profile: return AWS_PROFILE_SECTION_TYPE_PROFILE
        case .ssoSession: return AWS_PROFILE_SECTION_TYPE_SSO_SESSION
        }
    }
}

extension FileBasedConfiguration.Section {
    /// Represents a section property in the file based configuration.
    public class Property {
        let rawValue: OpaquePointer
        // Keep a reference of configuration to keep it alive
        let fileBasedConfiguration: FileBasedConfiguration

        init(rawValue: OpaquePointer, fileBasedConfiguration: FileBasedConfiguration) {
            self.rawValue = rawValue
            self.fileBasedConfiguration = fileBasedConfiguration
        }

        /// Returns the property's string value
        public var value: String {
            let awsString = aws_profile_property_get_value(rawValue)!
            return String(awsString: awsString)!
        }

        /// Returns the value of a sub property with the given name, if it exists, in the property
        /// - Parameters:
        ///   - name: The name of the sub property value to retrieve
        /// - Returns: value of sub property if it exists.
        public func getSubProperty(name: String) -> String? {
            let awsString = AWSString(name)
            guard let stringPointer = aws_profile_property_get_sub_property(rawValue, awsString.rawValue) else {
                return nil
            }
            return String(awsString: stringPointer)
        }

        /// Returns how many sub properties the property holds
        public var subPropertyCount: Int {
            aws_profile_property_get_sub_property_count(rawValue)
        }
    }
}
