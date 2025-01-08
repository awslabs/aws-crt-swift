//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

/// Type of Host Address (ipv4 or ipv6)
public enum HostAddressType: Sendable {
    case A
    case AAAA
}

extension HostAddressType: CaseIterable {

    init(rawValue: aws_address_record_type) {
        self = Self.allCases.first(where: {$0.rawValue == rawValue})!
    }

    var rawValue: aws_address_record_type {
        switch self {
        case .A:  return AWS_ADDRESS_RECORD_TYPE_A
        case .AAAA:  return AWS_ADDRESS_RECORD_TYPE_AAAA
        }
    }
}
