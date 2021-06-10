//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

public enum CRTExponentialBackoffJitterMode {
    /* Uses AWS_EXPONENTIAL_BACKOFF_JITTER_FULL */
    case `default`
    case none
    case full
    case decorrelated
}

extension CRTExponentialBackoffJitterMode: RawRepresentable, CaseIterable {

    public init(rawValue: aws_exponential_backoff_jitter_mode) {
        let value = Self.allCases.first { $0.rawValue == rawValue }
        self = value ?? .default
    }
    public var rawValue: aws_exponential_backoff_jitter_mode {
        switch self {
        case .default:  return aws_exponential_backoff_jitter_mode(rawValue: 0)
        case .none:  return aws_exponential_backoff_jitter_mode(rawValue: 1)
        case .full: return aws_exponential_backoff_jitter_mode(rawValue: 2)
        case .decorrelated: return aws_exponential_backoff_jitter_mode(rawValue: 3)
        }
    }
}
