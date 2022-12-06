//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

public enum RetryError {
    /** This is a connection level error such as a socket timeout, socket connect error, tls negotiation timeout etc...
     * Typically these should never be applied for non-idempotent request types since in this scenario, it's impossible
     * to know whether the operation had a side effect on the server. */
    case transient
    /** This is an error where the server explicitly told the client to back off, such as a 429 or 503 Http error. */
    case throttling
    /** This is a server error that isn't explicitly throttling but is considered by the client
     * to be something that should be retried. */
    case serverError
    /** Doesn't count against any budgets. This could be something like a 401 challenge in Http. */
    case clientError
}

extension RetryError: RawRepresentable, CaseIterable {

    public init(rawValue: aws_retry_error_type) {
        let value = Self.allCases.first { $0.rawValue == rawValue }
        self = value ?? .transient
    }
    public var rawValue: aws_retry_error_type {
        switch self {
        case .transient:  return aws_retry_error_type(rawValue: 0)
        case .throttling:  return aws_retry_error_type(rawValue: 1)
        case .serverError: return aws_retry_error_type(rawValue: 2)
        case .clientError: return aws_retry_error_type(rawValue: 3)
        }
    }
}
