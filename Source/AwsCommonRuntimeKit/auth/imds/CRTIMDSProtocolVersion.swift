//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth

public enum CRTIMDSProtocolVersion {
    case v2
    case v1
}

extension CRTIMDSProtocolVersion: RawRepresentable, CaseIterable {

    public init(rawValue: aws_imds_protocol_version) {
        let value = Self.allCases.first(where: {$0.rawValue == rawValue})
        self = value ?? .v2
    }
    
    public var rawValue: aws_imds_protocol_version {
        switch self {
        case .v2: return IMDS_PROTOCOL_V2
        case .v1: return IMDS_PROTOCOL_V1
        }
    }
}
