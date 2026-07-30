//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

/// Controls how the reconnect delay is modified in order to smooth out the distribution of reconnection attempt
/// timepoints for a large set of reconnecting clients.
/// See `Exponential Backoff and Jitter <https:///aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/>`_
public enum ExponentialBackoffJitterMode {
  /// Maps to full
  /// Link to documentation: https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
  case `default`

  /// Do not perform any randomization on the reconnect delay
  case none

  /// Fully random between no delay and the current exponential backoff value.
  case full

  /// Backoff is taken randomly from the interval between the base backoff
  /// interval and a scaling (greater than 1) of the current backoff value
  case decorrelated
}

extension ExponentialBackoffJitterMode {
  var rawValue: aws_exponential_backoff_jitter_mode {
    switch self {
    case .default: return aws_exponential_backoff_jitter_mode(rawValue: 0)
    case .none: return aws_exponential_backoff_jitter_mode(rawValue: 1)
    case .full: return aws_exponential_backoff_jitter_mode(rawValue: 2)
    case .decorrelated: return aws_exponential_backoff_jitter_mode(rawValue: 3)
    }
  }
}
