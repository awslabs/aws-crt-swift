//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCSdkUtils

public class AWSProfileProperty {
    let rawValue: OpaquePointer
    // Keep a reference of collection to keep it alive
    let collection: AWSProfileCollection

    init(rawValue: OpaquePointer, collection: AWSProfileCollection) {
        self.rawValue = rawValue
        self.collection = collection
    }

    /// Returns the property's string value
    public var value: String {
        let awsString = aws_profile_property_get_value(rawValue)!
        return String(awsString: awsString)!
    }

    /// Returns the value of a sub property with the given name, if it exists, in the property
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
