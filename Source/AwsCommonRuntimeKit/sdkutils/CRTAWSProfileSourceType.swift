//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCSdkUtils

public enum CRTAWSProfileSourceType {
    case none
    case config
    case credentials
}

extension CRTAWSProfileSourceType: RawRepresentable, CaseIterable {

    public init(rawValue: aws_profile_source_type) {
        let value = Self.allCases.first(where: {$0.rawValue == rawValue})
        self = value ?? .none
    }

    public static func fromString(string: String) -> CRTAWSProfileSourceType {
        switch string {
        case "AWS_PST_NONE":
            return .none
        case "AWS_PST_CONFIG":
            return .config
        case "AWS_PST_CREDENTIALS":
            return .credentials
        default:
            return .none
        }
    }

    public var rawValue: aws_profile_source_type {
        switch self {
        case .none: return AWS_PST_NONE
        case .config: return AWS_PST_CONFIG
        case .credentials: return AWS_PST_CREDENTIALS
        }
    }
}
