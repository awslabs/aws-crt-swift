//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCAuth

public enum ImdsProtocolVersion {
     /// Defaults to IMDS_PROTOCOL_V2. It can be set to either one and IMDS Client
     /// will figure out (by looking at response code) which protocol an instance
     /// is using. But a more clear setting will reduce unnecessary network request.
    case imds_protocol_v2
    case imds_protocol_v1
}

extension ImdsProtocolVersion: RawRepresentable, CaseIterable {

    public init(rawValue: aws_imds_protocol_version) {
        let value = Self.allCases.first(where: {$0.rawValue == rawValue})
        self = value ?? .imds_protocol_v2
    }

    public var rawValue: aws_imds_protocol_version {
        switch self {
        case .imds_protocol_v2:  return IMDS_PROTOCOL_V2
        case .imds_protocol_v1: return IMDS_PROTOCOL_V1
        }
    }
}
