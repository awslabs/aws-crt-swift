//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AwsCIo

public enum AddressRecordType {
    case typeA
    case typeAAAA
}

extension AddressRecordType: RawRepresentable, CaseIterable {
    public init(rawValue: aws_address_record_type) {
        let value = Self.allCases.first { $0.rawValue == rawValue }
        self = value ?? .typeA
    }

    public var rawValue: aws_address_record_type {
        switch self {
        case .typeA: return aws_address_record_type(rawValue: 0)
        case .typeAAAA: return aws_address_record_type(rawValue: 1)
        }
    }
}
