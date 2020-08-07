//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCAuth

enum SignedBodyHeaderType {

    /// Do not add a header
    case none

    /// Add the "x-amz-content-sha256" header with the canonical request's body value
    case contentSha256
}

extension SignedBodyHeaderType: RawRepresentable, CaseIterable {
    public init(rawValue: aws_signed_body_header_type) {
        let value = Self.allCases.first(where: {$0.rawValue == rawValue})
        self = value ?? .none
    }
    public var rawValue: aws_signed_body_header_type {
        switch self {
        case .none: return AWS_SBHT_NONE
        case .contentSha256: return AWS_SBHT_X_AMZ_CONTENT_SHA256
        }
    }
}
