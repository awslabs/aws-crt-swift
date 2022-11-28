//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import struct Foundation.Date
import struct Foundation.Data
import struct Foundation.TimeInterval
import AwsCCal

extension String {

    public func base64EncodedMD5(allocator: Allocator = defaultAllocator, truncate: Int = 0) throws -> String {
        let bufferSize = 16
        var bufferData = Data(count: bufferSize)
        try bufferData.withUnsafeMutableBytes { bufferPointer in
            var buffer = aws_byte_buf_from_empty_array(bufferPointer.baseAddress, bufferSize)
            guard self.withByteCursorPointer({ strCursorPointer in
                aws_md5_compute(allocator.rawValue, strCursorPointer, &buffer, truncate)
            }) == AWS_OP_SUCCESS else {
                throw CommonRunTimeError.crtError(.makeFromLastError())
            }
        }
        return bufferData.base64EncodedString()
    }

    func withByteCursor<Result>(_ body: (aws_byte_cursor) -> Result
    ) -> Result {
        return self.withCString { arg1C in
            return body(aws_byte_cursor_from_c_str(arg1C))
        }
    }

    func withByteCursorPointer<Result>(_ body: (UnsafePointer<aws_byte_cursor>) -> Result
    ) -> Result {
        return self.withCString { arg1C in
            return withUnsafePointer(to: aws_byte_cursor_from_c_str(arg1C)) { byteCursorPointer in
                return body(byteCursorPointer)
            }
        }
    }
}

extension Data {

    /// Computes the sha256 hash over data.
    /// Use this if you don't need to stream the data you're hashing and you can load
    /// the entire input to hash into memory. If you specify truncate_to to something
    /// other than 0, the output will be truncated to that number of bytes. For
    /// example, if you want a SHA256 digest as the first 16 bytes, set truncate_to
    /// to 16. If you want the full digest size, just set this to 0.
    func sha256(truncate: Int = 0, allocator: Allocator = defaultAllocator) throws -> Data {
        try self.withUnsafeBytes { bufferPointer in
            var byteCursor = aws_byte_cursor_from_array(bufferPointer.baseAddress, count)
            let bufferSize = Int(AWS_SHA256_LEN)
            var bufferData = Data(count: bufferSize)
            try bufferData.withUnsafeMutableBytes { bufferDataPointer in
                var buffer = aws_byte_buf_from_empty_array(bufferDataPointer.baseAddress, bufferSize)
                guard aws_sha256_compute(allocator.rawValue, &byteCursor, &buffer, truncate) == AWS_OP_SUCCESS else {
                    throw CommonRunTimeError.crtError(.makeFromLastError())
                }
            }
            return bufferData
        }
    }
}

extension aws_date_time {
    func toDate() -> Date {
        let timeInterval = withUnsafePointer(to: self, aws_date_time_as_epoch_secs)
        return Date(timeIntervalSince1970: timeInterval)
    }
}

extension Date {
    func toAWSDate() -> aws_date_time {
        var date = aws_date_time()
        aws_date_time_init_epoch_secs(&date, self.timeIntervalSince1970)
        return date
    }
}

extension TimeInterval {
    var millisecond: UInt64 {
        UInt64(self*1000)
    }
}

extension aws_byte_cursor {
    func toString() -> String {
        let data = Data(bytesNoCopy: self.ptr, count: self.len, deallocator: .none)
        return String(data: data, encoding: .utf8)!
    }

    func toOptionalString() -> String? {
        if self.len == 0 { return nil }
        let data = Data(bytesNoCopy: self.ptr, count: self.len, deallocator: .none)
        return String(data: data, encoding: .utf8)!
    }
}

extension aws_array_list {
    func byteCursorListToStringArray() -> [String] {
        var arrayList = self
        var result = [String]()

        for index in 0..<self.length {
            var val: UnsafeMutableRawPointer!
            aws_array_list_get_at_ptr(&arrayList, &val, index)
            let byteCursor = val.bindMemory(to: aws_byte_cursor.self, capacity: 1).pointee
            result.append(byteCursor.toString())
        }
        return result
    }

    func awsStringListToStringArray() -> [String] {
        var arrayList = self
        var result = [String]()

        for index in 0..<self.length {
                var valPtr: UnsafeMutableRawPointer! = nil
                aws_array_list_get_at(&arrayList, &valPtr, index)
                let strPtr = valPtr.bindMemory(to: aws_string.self, capacity: 1)
                result.append(String(awsString: strPtr)!)
        }
        return result
    }
}

extension Bool {
    var uintValue: UInt32 {
        return self ? 1 : 0
    }
}

func withOptionalCString<Result>(
        to arg1: String?, _ body: (UnsafePointer<Int8>?) -> Result) -> Result {
    if let arg1 = arg1 {
        return arg1.withCString { cString in
            return body(cString)
        }
    }
    return body(nil)
}

func withOptionalByteCursorPointerFromString<Result>(
        _ arg1: String?, _ body: (UnsafePointer<aws_byte_cursor>?) -> Result
) -> Result {
    guard let arg1 = arg1 else {
        return body(nil)
    }
    return arg1.withCString { arg1C in
        withUnsafePointer(to: aws_byte_cursor_from_c_str(arg1C)) { byteCursorPointer in
            body(byteCursorPointer)
        }
    }
}

func withByteCursorFromStrings<Result>(
        _ arg1: String?, _ body: (aws_byte_cursor) -> Result
) -> Result {
    return withOptionalCString(to: arg1) { arg1C in
        return body(aws_byte_cursor_from_c_str(arg1C))
    }
}

func withByteCursorFromStrings<Result>(
        _ arg1: String?, _ arg2: String?, _ body: (aws_byte_cursor, aws_byte_cursor) -> Result
) -> Result {
    return withOptionalCString(to: arg1) { arg1C in
        return withOptionalCString(to: arg2) { arg2C in
                return body(aws_byte_cursor_from_c_str(arg1C), aws_byte_cursor_from_c_str(arg2C))
        }
    }
}

func withByteCursorFromStrings<Result>(
        _ arg1: String?, _ arg2: String?, _ arg3: String?, _ body: (aws_byte_cursor, aws_byte_cursor, aws_byte_cursor) -> Result
) -> Result {
    return withOptionalCString(to: arg1) { arg1C in
        return withOptionalCString(to: arg2) { arg2C in
            return withOptionalCString(to: arg3) {arg3c in
                return body(aws_byte_cursor_from_c_str(arg1C), aws_byte_cursor_from_c_str(arg2C), aws_byte_cursor_from_c_str(arg3c))
            }
        }
    }
}
