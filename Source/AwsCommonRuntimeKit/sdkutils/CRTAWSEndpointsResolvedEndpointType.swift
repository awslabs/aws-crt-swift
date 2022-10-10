//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCSdkUtils

/// Resolved endpoint type
public enum CRTAWSEndpointsResolvedEndpointType {
    /// Used for endpoints that are resolved successfully
    case endpoint
    /// Used for endpoints that resolve to an error
    case error
}

extension CRTAWSEndpointsResolvedEndpointType: RawRepresentable, CaseIterable {
    public init(rawValue: aws_endpoints_resolved_endpoint_type) {
        let value = Self.allCases.first(where: {$0.rawValue == rawValue})
        self = value ?? .endpoint
    }

    public var rawValue: aws_endpoints_resolved_endpoint_type {
        switch self {
        case .endpoint:
            return AWS_ENDPOINTS_RESOLVED_ENDPOINT
        case .error:
            return AWS_ENDPOINTS_RESOLVED_ERROR
        }
    }
}
