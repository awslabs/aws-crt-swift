//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

public enum HostAddressType {
    case A
    case AAAA
}

extension HostAddressType: RawRepresentable, CaseIterable {

    public init(rawValue: aws_address_record_type) {
        let value = Self.allCases.first { $0.rawValue == rawValue }
        self = value ?? .A
    }
    public var rawValue: aws_address_record_type {
        switch self {
        case .A:  return aws_address_record_type(rawValue: 0)
        case .AAAA:  return aws_address_record_type(rawValue: 1)
        }
    }
}
