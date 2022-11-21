//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCSdkUtils

public struct CRTAWSProfile {
    let rawValue: OpaquePointer

    init(rawValue: OpaquePointer) {
        self.rawValue = rawValue
    }

    /// Returns a reference to the name of the provided profile
    public var name: String? {
        guard let string = aws_profile_get_name(rawValue) else {
            return nil
        }
        return String(awsString: string)
    }

    /// Retrieves a reference to a property with the specified name, if it exists, from a profile
    public func getProperty(name: String, allocator: Allocator = defaultAllocator) -> CRTAWSProfileProperty? {
        let nameAwsString = AWSString(name, allocator: allocator)
        guard let propPointer = aws_profile_get_property(rawValue, nameAwsString.rawValue) else {
            return nil
        }
        return CRTAWSProfileProperty(rawValue: propPointer)
    }

    /// Returns how many properties a profile holds
    public var propertyCount: Int {
       aws_profile_get_property_count(rawValue)
    }
}
