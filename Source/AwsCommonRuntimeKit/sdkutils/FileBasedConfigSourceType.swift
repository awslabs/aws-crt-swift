//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCSdkUtils

public enum FileBasedConfigSourceType {
    case config
    case credentials
}

extension FileBasedConfigSourceType {
    var rawValue: aws_profile_source_type {
        switch self {
        case .config: return AWS_PST_CONFIG
        case .credentials: return AWS_PST_CREDENTIALS
        }
    }
}

public enum FileBasedConfigSectionType {
    case profile
    case sso_session
}

extension FileBasedConfigSectionType {
    var rawValue: aws_profile_section_type {
        switch self {
        case .profile: return AWS_PROFILE_SECTION_TYPE_PROFILE
        case .sso_session: return AWS_PROFILE_SECTION_TYPE_SSO_SESSION
        }
    }
}