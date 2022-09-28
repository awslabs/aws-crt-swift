//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCCommon

enum DayOfWeek {
    case sunday
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
}

extension DayOfWeek: RawRepresentable, CaseIterable {
    public init(rawValue: aws_date_day_of_week) {
        let value = Self.allCases.first(where: { $0.rawValue == rawValue })
        self = value ?? .sunday
    }

    public var rawValue: aws_date_day_of_week {
        switch self {
        case .sunday: return aws_date_day_of_week(0)
        case .monday: return aws_date_day_of_week(1)
        case .tuesday: return aws_date_day_of_week(2)
        case .wednesday: return aws_date_day_of_week(3)
        case .thursday: return aws_date_day_of_week(4)
        case .friday: return aws_date_day_of_week(5)
        case .saturday: return aws_date_day_of_week(6)
        }
    }
}
