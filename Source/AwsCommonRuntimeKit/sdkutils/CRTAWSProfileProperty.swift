//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AwsCSdkUtils

public struct CRTAWSProfileProperty {
    let rawValue: OpaquePointer

    public init(rawValue: OpaquePointer) {
        self.rawValue = rawValue
    }

    public var value: String? {
        guard let awsString = aws_profile_property_get_value(rawValue) else {
            return nil
        }
        return String(awsString: awsString)
    }

    public func getSubProperty(name: String, allocator: Allocator = defaultAllocator) -> String? {
        let awsString = AWSString(name, allocator: allocator)
        guard let stringPointer = aws_profile_property_get_sub_property(rawValue, awsString.rawValue) else {
            return nil
        }
        return String(awsString: stringPointer)
    }

    public var subPropertyCount: Int {
        aws_profile_property_get_sub_property_count(rawValue)
    }
}
