//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

/// Type of Host Address (ipv4 or ipv6)
public enum HostAddressType {
    case A
    case AAAA
}

extension HostAddressType: RawRepresentable, CaseIterable {

    public init(rawValue: aws_address_record_type) {
        let value = Self.allCases.first { $0.rawValue == rawValue }
        guard let value = value else {
            fatalError("Unexpected HostAddressType found")
        }
        self = value
    }
    public var rawValue: aws_address_record_type {
        switch self {
        case .A:  return AWS_ADDRESS_RECORD_TYPE_A
        case .AAAA:  return AWS_ADDRESS_RECORD_TYPE_AAAA
        }
    }
}
