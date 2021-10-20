//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth

public struct CRTIAMProfile {
    public let lastUpdated: AWSDate
    public let profileArn: String
    public let profileId: String

    init(pointer: UnsafePointer<aws_imds_iam_profile>) {
        let profile = pointer.pointee
        self.lastUpdated = AWSDate(rawValue: profile.last_updated)
        self.profileArn = profile.instance_profile_arn.toString() ?? ""
        self.profileId = profile.instance_profile_id.toString() ?? ""

    }
}
