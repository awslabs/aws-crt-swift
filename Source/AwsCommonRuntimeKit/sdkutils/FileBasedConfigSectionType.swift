//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCSdkUtils

/// Type of section in a config file
public enum FileBasedConfigSectionType {
    case profile
    case ssoSession
}

extension FileBasedConfigSectionType {
    var rawValue: aws_profile_section_type {
        switch self {
        case .profile: return AWS_PROFILE_SECTION_TYPE_PROFILE
        case .ssoSession: return AWS_PROFILE_SECTION_TYPE_SSO_SESSION
        }
    }
}
