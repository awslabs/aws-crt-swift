//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCSdkUtils

public enum ProfileSourceType {
    case config
    case credentials
}

extension ProfileSourceType {
    var rawValue: aws_profile_source_type {
        switch self {
        case .config: return AWS_PST_CONFIG
        case .credentials: return AWS_PST_CREDENTIALS
        }
    }
}
