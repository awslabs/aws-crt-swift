//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCSdkUtils

/// Represents a section property in the file based configuration.
public class FileBasedConfigurationSectionProperty {
    let rawValue: OpaquePointer
    // Keep a reference of collection to keep it alive
    let collection: FileBasedConfiguration

    init(rawValue: OpaquePointer, collection: FileBasedConfiguration) {
        self.rawValue = rawValue
        self.collection = collection
    }

    /// Returns the property's string value
    public var value: String {
        let awsString = aws_profile_property_get_value(rawValue)!
        return String(awsString: awsString)!
    }

    /// Returns the value of a sub property with the given name, if it exists, in the property
    /// - Parameters:
    ///   - name: The name of the sub property value to retrieve
    ///   - allocator: (Optional) allocator to override
    /// - Returns: value of sub property if it exists.
    public func getSubProperty(name: String, allocator: Allocator = defaultAllocator) -> String? {
        let awsString = AWSString(name, allocator: allocator)
        guard let stringPointer = aws_profile_property_get_sub_property(rawValue, awsString.rawValue) else {
            return nil
        }
        return String(awsString: stringPointer)
    }

    /// Returns how many sub properties the property holds
    public var subPropertyCount: Int {
        return aws_profile_property_get_sub_property_count(rawValue)
    }
}
