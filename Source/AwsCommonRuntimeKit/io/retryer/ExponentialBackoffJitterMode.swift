//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

public enum ExponentialBackoffJitterMode {
    /// Uses AWS_EXPONENTIAL_BACKOFF_JITTER_FULL
    /// Link to documentation: https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
    case `default`
    case none
    case full
    case decorrelated
}

extension ExponentialBackoffJitterMode {
    var rawValue: aws_exponential_backoff_jitter_mode {
        switch self {
        case .default:  return aws_exponential_backoff_jitter_mode(rawValue: 0)
        case .none:  return aws_exponential_backoff_jitter_mode(rawValue: 1)
        case .full: return aws_exponential_backoff_jitter_mode(rawValue: 2)
        case .decorrelated: return aws_exponential_backoff_jitter_mode(rawValue: 3)
        }
    }
}
