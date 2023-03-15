//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCSdkUtils

/// Represents a section in the FileBasedConfiguration
public class FileBasedConfigurationSection {
    let rawValue: OpaquePointer
    // Keep a reference of collection to keep it alive
    let collection: FileBasedConfiguration

    init(rawValue: OpaquePointer, collection: FileBasedConfiguration) {
        self.rawValue = rawValue
        self.collection = collection
    }

    /// Returns a reference to the name of the provided profile
    public var name: String {
        String(awsString: aws_profile_get_name(rawValue))!
    }

    /// Retrieves a reference to a property with the specified name, if it exists, from a profile
    /// - Parameters:
    ///   - name: The name of property to retrieve
    ///   - allocator: (Optional) default allocator to override
    /// - Returns:
    public func getProperty(name: String, allocator: Allocator = defaultAllocator) -> FileBasedConfigurationSectionProperty? {
        let nameAwsString = AWSString(name, allocator: allocator)
        guard let propPointer = aws_profile_get_property(rawValue, nameAwsString.rawValue) else {
            return nil
        }
        return FileBasedConfigurationSectionProperty(rawValue: propPointer, collection: collection)
    }

    /// Returns how many properties a section holds
    public var propertyCount: Int {
        aws_profile_get_property_count(rawValue)
    }
}
