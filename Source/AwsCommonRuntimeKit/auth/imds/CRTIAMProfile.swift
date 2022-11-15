//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth
import Foundation

public struct CRTIAMProfile {
    public var lastUpdated: Date
    public var profileArn: String?
    public var profileId: String?

    init(profile: aws_imds_iam_profile) {
        self.lastUpdated = profile.last_updated.toDate()
        self.profileArn = profile.instance_profile_arn.toString()
        self.profileId = profile.instance_profile_id.toString()
    }
}
