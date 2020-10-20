//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCCommon

enum DateMonth {
    case january
    case february
    case march
    case april
    case may
    case june
    case july
    case august
    case september
    case october
    case november
    case december
}

extension DateMonth: RawRepresentable, CaseIterable {
    public init(rawValue: aws_date_month) {
        let value = Self.allCases.first(where: {$0.rawValue == rawValue})
        self = value ?? .january
    }
    public var rawValue: aws_date_month {
        switch self {
        case .january: return aws_date_month(0)
        case .february: return aws_date_month(1)
        case .march: return aws_date_month(2)
        case .april: return aws_date_month(3)
        case .may: return aws_date_month(4)
        case .june: return aws_date_month(5)
        case .july: return aws_date_month(6)
        case .august: return aws_date_month(7)
        case .september: return aws_date_month(8)
        case .october: return aws_date_month(9)
        case .november: return aws_date_month(10)
        case .december: return aws_date_month(11)
        }
    }
}
