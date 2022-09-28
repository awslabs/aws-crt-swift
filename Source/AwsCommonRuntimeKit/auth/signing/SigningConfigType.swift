//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth

public enum SigningConfigType {
    case aws
}

extension SigningConfigType: RawRepresentable, CaseIterable {
    public init(rawValue: aws_signing_config_type) {
        let value = Self.allCases.first(where: { $0.rawValue == rawValue })
        self = value ?? .aws
    }

    public var rawValue: aws_signing_config_type {
        switch self {
        case .aws: return AWS_SIGNING_CONFIG_AWS
        }
    }
}
