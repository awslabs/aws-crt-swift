//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth

enum SignedBodyValueType {

    /// Use the SHA-256 of the empty string.
    case empty

    /// Use the SHA-256 of the actual (request/chunk/event) payload.
    case payload

    /// Use the literal string 'UNSIGNED-PAYLOAD'
    case unsignedPayload

    /// Use the literal string 'STREAMING-AWS4-HMAC-SHA256-PAYLOAD'
    case streamingSha256Payload

    /// Use the literal string 'STREAMING-AWS4-HMAC-SHA256-EVENTS'
    /// Event signing is not yet supported
    case streamingSha256Events
}

extension SignedBodyValueType: RawRepresentable, CaseIterable {
    public init(rawValue: aws_signed_body_value_type) {
        let value = Self.allCases.first(where: {$0.rawValue == rawValue})
        self = value ?? .empty
    }
    public var rawValue: aws_signed_body_value_type {
        switch self {
        case .empty: return AWS_SBVT_EMPTY
        case .payload: return AWS_SBVT_PAYLOAD
        case .unsignedPayload: return AWS_SBVT_UNSIGNED_PAYLOAD
        case .streamingSha256Payload: return AWS_SBVT_STREAMING_AWS4_HMAC_SHA256_PAYLOAD
        case .streamingSha256Events: return AWS_SBVT_STREAMING_AWS4_HMAC_SHA256_EVENTS
        }
    }
}
