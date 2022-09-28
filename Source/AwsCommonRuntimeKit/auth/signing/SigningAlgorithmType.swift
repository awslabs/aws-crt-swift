//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AwsCAuth

public enum SigningAlgorithmType {
    case signingV4
}

extension SigningAlgorithmType: RawRepresentable, CaseIterable {
    public init(rawValue: aws_signing_algorithm) {
        let value = Self.allCases.first(where: { $0.rawValue == rawValue })
        self = value ?? .signingV4
    }

    public var rawValue: aws_signing_algorithm {
        switch self {
        case .signingV4: return AWS_SIGNING_ALGORITHM_V4
        }
    }
}
