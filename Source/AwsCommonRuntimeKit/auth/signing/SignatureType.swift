//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth

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

extension SignatureType: RawRepresentable, CaseIterable {
    public init(rawValue: aws_signature_type) {
        let value = Self.allCases.first(where: { $0.rawValue == rawValue })
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
