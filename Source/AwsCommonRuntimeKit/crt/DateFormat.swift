//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCCommon

enum DateFormat {
    case rfc822
    case iso8601
    case iso8601Basic
    case autoDetect
}

extension DateFormat: CaseIterable, RawRepresentable {
    public init(rawValue: aws_date_format) {
        let value = Self.allCases.first(where: { $0.rawValue == rawValue })
        self = value ?? .rfc822
    }

    public var rawValue: aws_date_format {
        switch self {
        case .rfc822: return aws_date_format(0)
        case .iso8601: return aws_date_format(1)
        case .iso8601Basic: return aws_date_format(2)
        case .autoDetect: return aws_date_format(3)
        }
    }
}
