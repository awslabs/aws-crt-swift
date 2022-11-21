//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth
import Foundation

public enum SignatureType {
    /**
     A signature for a full http request should be computed, with header updates applied to the signing result.
     */
    case requestHeaders

    /**
     A signature for a full http request should be computed, with query param updates applied to the signing result.
     */
    case requestQueryParams

    /**
     Compute a signature for a payload chunk.  The signable's input stream should be the chunk data and the
     signable should contain the most recent signature value (either the original http request or the most recent
     chunk) in the "previous-signature" property.
     */
    case requestChunk

    /**
     Compute a signature for an event stream event.  The signable's input stream should be the event payload, the
     signable should contain the most recent signature value (either the original http request or the most recent
     event) in the "previous-signature" property as well as any event headers that should be signed with the
     exception of ":date"

     This option is not yet supported.
     */
    case requestEvent
}

public enum SignedBodyHeaderType {

    /// Do not add a header
    case none

    /// Add the "x-amz-content-sha256" header with the canonical request's body value
    case contentSha256
}

public enum SignedBodyValue: String {
    /// if string is empty  a public value  will be calculated from the payload during signing
    case empty = ""
    case emptySha256 = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
    /// Use this in the case of needing to not use the payload for signing
    case unsignedPayload = "UNSIGNED-PAYLOAD"
    case streamingSha256Payload = "STREAMING-AWS4-HMAC-SHA256-PAYLOAD"
    case streamingSha256Events = "STREAMING-AWS4-HMAC-SHA256-EVENTS"
}

public enum SigningAlgorithmType {
    case signingV4
    case signingV4Asymmetric
}

extension SignatureType: RawRepresentable, CaseIterable {

    public init(rawValue: aws_signature_type) {
        let value = Self.allCases.first(where: {$0.rawValue == rawValue})
        self = value ?? .requestHeaders
    }

    public var rawValue: aws_signature_type {
        switch self {
        case .requestHeaders: return AWS_ST_HTTP_REQUEST_HEADERS
        case .requestQueryParams: return AWS_ST_HTTP_REQUEST_QUERY_PARAMS
        case .requestChunk: return AWS_ST_HTTP_REQUEST_CHUNK
        case .requestEvent: return AWS_ST_HTTP_REQUEST_EVENT
        }
    }
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

extension SigningAlgorithmType: RawRepresentable, CaseIterable {

    public init(rawValue: aws_signing_algorithm) {
        let value = Self.allCases.first(where: {$0.rawValue == rawValue})
        self = value ?? .signingV4
    }
    public var rawValue: aws_signing_algorithm {
        switch self {
        case .signingV4: return AWS_SIGNING_ALGORITHM_V4
        case .signingV4Asymmetric: return AWS_SIGNING_ALGORITHM_V4_ASYMMETRIC
        }
    }
}
