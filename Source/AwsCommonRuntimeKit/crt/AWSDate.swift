//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCCommon

class AWSDate: Comparable {
    let rawValue: UnsafeMutablePointer<aws_date_time>

    var year: UInt16 {
        aws_date_time_year(rawValue, true)
    }

    var month: DateMonth {
        DateMonth(rawValue: aws_date_time_month(rawValue, true))
    }

    var day: UInt8 {
        aws_date_time_month_day(rawValue, true)
    }

    var dayOfWeek: DayOfWeek {
        DayOfWeek(rawValue: aws_date_time_day_of_week(rawValue, true))
    }

    var hour: UInt8 {
        aws_date_time_hour(rawValue, true)
    }

    var minute: UInt8 {
        aws_date_time_minute(rawValue, true)
    }

    var isDST: Bool {
        aws_date_time_dst(rawValue, true)
    }

    var seconds: UInt8 {
        aws_date_time_second(rawValue, true)
    }

    init() {
        self.rawValue = UnsafeMutablePointer<aws_date_time>.allocate(capacity: 1)
        rawValue.initialize(to: aws_date_time())
        aws_date_time_init_now(rawValue)
    }
    init(epochMs: UInt64) {
        self.rawValue = UnsafeMutablePointer<aws_date_time>.allocate(capacity: 1)
        aws_date_time_init_epoch_millis(rawValue, epochMs)
    }

    init(epochS: Double) {
        self.rawValue = UnsafeMutablePointer<aws_date_time>.allocate(capacity: 1)
        aws_date_time_init_epoch_secs(rawValue, epochS)
    }

    init(timestamp: String) {
        self.rawValue = UnsafeMutablePointer<aws_date_time>.allocate(capacity: 1)
        let pointer = UnsafeMutablePointer<aws_byte_cursor>.allocate(capacity: 1)
        pointer.initialize(to: timestamp.awsByteCursor)
        defer { pointer.deinitializeAndDeallocate()}
        aws_date_time_init_from_str_cursor(rawValue, pointer, DateFormat.autoDetect.rawValue)
    }

    static func == (lhs: AWSDate, rhs: AWSDate) -> Bool {
        return aws_date_time_diff(lhs.rawValue, rhs.rawValue) == 0
    }

    static func < (lhs: AWSDate, rhs: AWSDate) -> Bool {
        return aws_date_time_diff(lhs.rawValue, rhs.rawValue) < 0
    }

    static func > (lhs: AWSDate, rhs: AWSDate) -> Bool {
        return aws_date_time_diff(lhs.rawValue, rhs.rawValue) > 0
    }

    static func <= (lhs: AWSDate, rhs: AWSDate) -> Bool {
        return aws_date_time_diff(lhs.rawValue, rhs.rawValue) <= 0
    }

    static func >= (lhs: AWSDate, rhs: AWSDate) -> Bool {
        return aws_date_time_diff(lhs.rawValue, rhs.rawValue) >= 0
    }

    static func - (lhs: AWSDate, rhs: AWSDate) -> AWSDate {
        var currentTime = aws_date_time_as_millis(lhs.rawValue)
        let timeToSubtractBy = aws_date_time_as_millis(rhs.rawValue)
        currentTime -= timeToSubtractBy
        return AWSDate(epochMs: currentTime)
    }

    static func + (lhs: AWSDate, rhs: AWSDate) -> AWSDate {
        var currentTime = aws_date_time_as_millis(lhs.rawValue)
        let timeToAdd = aws_date_time_as_millis(rhs.rawValue)
        currentTime += timeToAdd
        return AWSDate(epochMs: currentTime)
    }

    static func now() -> AWSDate {
        return AWSDate()
    }

    deinit {
        rawValue.deinitializeAndDeallocate()
    }
}

extension AWSDate {
    func toLocalTimeString(format: DateFormat) -> String? {
        let stringPtr = UnsafeMutablePointer<aws_byte_buf>.allocate(capacity: 1)
        if aws_date_time_to_local_time_str(rawValue, format.rawValue, stringPtr) == AWS_OP_SUCCESS {
            let byteCursor = aws_byte_cursor_from_buf(stringPtr)
            return byteCursor.toString()
        } else {
            return nil
        }
    }

    func toGMTString(format: DateFormat) -> String? {
       let stringPtr = UnsafeMutablePointer<aws_byte_buf>.allocate(capacity: 1)
        if aws_date_time_to_utc_time_str(rawValue, format.rawValue, stringPtr) == AWS_OP_SUCCESS {
            let byteCursor = aws_byte_cursor_from_buf(stringPtr)
            return byteCursor.toString()
        } else {
            return nil
        }
    }

    func toSecondsWithMsPrecision() -> Double {
        return aws_date_time_as_epoch_secs(rawValue)
    }

    func asMillis() -> UInt64 {
        return aws_date_time_as_millis(rawValue)
    }
}
