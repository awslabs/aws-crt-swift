//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCSdkUtils

public struct CRTAWSProfile {
    let rawValue: OpaquePointer

    public init(rawValue: OpaquePointer) {
        self.rawValue = rawValue
    }

    public var name: String? {
        guard let string = aws_profile_get_name(rawValue) else {
            return nil
        }
        return String(awsString: string)
    }

    public func getProperty(name: String, allocator: Allocator = defaultAllocator) -> CRTAWSProfileProperty? {
        let nameAwsString = AWSString(name, allocator: allocator)
        guard let propPointer = aws_profile_get_property(rawValue, nameAwsString.rawValue) else {
            return nil
        }
        return CRTAWSProfileProperty(rawValue: propPointer)
    }

    public var propertyCount: Int {
       return aws_profile_get_property_count(rawValue)
    }
}
