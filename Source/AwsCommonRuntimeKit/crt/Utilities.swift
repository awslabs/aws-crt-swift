//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import struct Foundation.Date
import struct Foundation.Data
import struct Foundation.TimeInterval
import AwsCCal

/// This class is used to add reference counting to stuff that do not support it
/// like Structs, Closures, and Protocols etc by wrapping it in a Class.
/// This also allows us to use anything with Unmanaged which we required for C callbacks.
class Box<T> {
    let contents: T
    init(_ contents: T) {
        self.contents = contents
    }

    func passRetained() -> UnsafeMutableRawPointer {
        Unmanaged<Box>.passRetained(self).toOpaque()
    }

    func passUnretained() -> UnsafeMutableRawPointer {
        Unmanaged<Box>.passUnretained(self).toOpaque()
    }

    func release() {
        Unmanaged.passUnretained(self).release()
    }
}

extension String {

    func withByteCursor<Result>(_ body: (aws_byte_cursor) -> Result
    ) -> Result {
        return self.withCString { arg1C in
            return body(aws_byte_cursor_from_array(arg1C, self.utf8.count))
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

    func withAWSByteBufPointer<Result>(_ body: (UnsafeMutablePointer<aws_byte_buf>) -> Result) -> Result {
        let count = self.count
        return self.withUnsafeBytes { rawBufferPointer -> Result in
            var byteBuf = aws_byte_buf_from_array(rawBufferPointer.baseAddress, count)
            return withUnsafeMutablePointer(to: &byteBuf) {
                body($0)
            }
        }
    }

    func withAWSByteCursorPointer<Result>(_ body: (UnsafeMutablePointer<aws_byte_cursor>) -> Result) -> Result {
        let count = self.count
        return self.withUnsafeBytes { rawBufferPointer -> Result in
            var cursor = aws_byte_cursor_from_array(rawBufferPointer.baseAddress, count)
            return withUnsafeMutablePointer(to: &cursor) {
                body($0)
            }
        }
    }

    public func encodeToHexString() -> String {
        map { String(format: "%02x", $0) }.joined()
    }

    func chunked(into size: Int) -> [Data] {
        return stride(from: 0, to: count, by: size).map {
            self[$0 ..< Swift.min($0 + size, count)]
        }
    }
}

extension aws_date_time {
    func toDate() -> Date {
        let timeInterval = withUnsafePointer(to: self, aws_date_time_as_epoch_secs)
        return Date(timeIntervalSince1970: timeInterval)
    }
}

extension aws_byte_buf {
    func toString() -> String {
        return String(
            data: toData(),
            encoding: .utf8)!
    }

    func toData() -> Data {
        if self.len == 0 {
            return Data()
        }
        return Data(bytes: self.buffer, count: self.len)
    }
}

extension Date {
    func toAWSDate() -> aws_date_time {
        var date = aws_date_time()
        aws_date_time_init_epoch_secs(&date, self.timeIntervalSince1970)
        return date
    }

    var millisecondsSince1970: Int64 {
        Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }

    init(millisecondsSince1970: Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(millisecondsSince1970) / 1000)
    }
}

extension TimeInterval {
    var millisecond: UInt64 {
        UInt64((self*1000).rounded())
    }
}

extension aws_byte_cursor {
    func toData() -> Data {
        Data(bytes: self.ptr, count: self.len)
    }

    func toArray() -> [UInt8] {
        Array(UnsafeBufferPointer(start: self.ptr, count: self.len))
    }

    func toString() -> String {
        if self.len == 0 {
            return ""
        }

        let data = Data(bytesNoCopy: self.ptr, count: self.len, deallocator: .none)
        return String(decoding: data, as: UTF8.self)
    }

    func toOptionalString() -> String? {
        if self.len == 0 { return nil }
        let data = Data(bytesNoCopy: self.ptr, count: self.len, deallocator: .none)
        return String(data: data, encoding: .utf8)
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
    _ arg1: String?,
    _ body: (UnsafePointer<aws_byte_cursor>?) throws -> Result
) rethrows -> Result {
    guard let arg1 = arg1 else {
        return try body(nil)
    }
    return try arg1.withCString { arg1C in
        try withUnsafePointer(to: aws_byte_cursor_from_c_str(arg1C)) { byteCursorPointer in
            try body(byteCursorPointer)
        }
    }
}

func withOptionalByteCursorPointerFromStrings<Result>(
    _ arg1: String?,
    _ arg2: String?,
    _ body: (UnsafePointer<aws_byte_cursor>?, UnsafePointer<aws_byte_cursor>?) throws -> Result
) rethrows -> Result {
    return try withOptionalByteCursorPointerFromString(arg1) { arg1C in
        return try withOptionalByteCursorPointerFromString(arg2) { arg2C in
            return try body(arg1C, arg2C)
        }
    }
}

func withByteCursorFromStrings<Result>(
    _ arg1: String?,
    _ body: (aws_byte_cursor) -> Result
) -> Result {
    return withOptionalCString(to: arg1) { arg1C in
        return body(aws_byte_cursor_from_c_str(arg1C))
    }
}

func withByteCursorFromStrings<Result>(
    _ arg1: String?,
    _ arg2: String?,
    _ body: (aws_byte_cursor, aws_byte_cursor) -> Result
) -> Result {
    return withOptionalCString(to: arg1) { arg1C in
        return withOptionalCString(to: arg2) { arg2C in
            return body(
                aws_byte_cursor_from_c_str(arg1C),
                aws_byte_cursor_from_c_str(arg2C))
        }
    }
}

func withByteCursorFromStrings<Result>(
    _ arg1: String?,
    _ arg2: String?,
    _ arg3: String?,
    _ body: (aws_byte_cursor, aws_byte_cursor, aws_byte_cursor) -> Result
) -> Result {
    return withOptionalCString(to: arg1) { arg1C in
        return withOptionalCString(to: arg2) { arg2C in
            return withOptionalCString(to: arg3) {arg3c in
                return body(
                    aws_byte_cursor_from_c_str(arg1C),
                    aws_byte_cursor_from_c_str(arg2C),
                    aws_byte_cursor_from_c_str(arg3c))
            }
        }
    }
}

func withByteCursorFromStrings<Result>(
    _ arg1: String?,
    _ arg2: String?,
    _ arg3: String?,
    _ arg4: String?,
    _ body: (aws_byte_cursor, aws_byte_cursor, aws_byte_cursor, aws_byte_cursor) -> Result
) -> Result {
    return withOptionalCString(to: arg1) { arg1C in
        return withOptionalCString(to: arg2) { arg2C in
            return withOptionalCString(to: arg3) {arg3c in
                return withOptionalCString(to: arg4) {arg4c in
                    return body(
                        aws_byte_cursor_from_c_str(arg1C),
                        aws_byte_cursor_from_c_str(arg2C),
                        aws_byte_cursor_from_c_str(arg3c),
                        aws_byte_cursor_from_c_str(arg4c))
                }
            }
        }
    }
}

extension Array where Element == String {
  func withByteCursorArray<R>(_ body: (UnsafePointer<aws_byte_cursor>, Int) -> R) -> R {
        let len = self.count
        let cStrings = self.map { strdup($0) }
        let cursors = cStrings.map { aws_byte_cursor_from_c_str($0) }
        
        defer {
            cStrings.forEach { free($0) }
        }

        return cursors.withUnsafeBufferPointer { cursorsPtr in 
            return body(cursorsPtr.baseAddress!, len)
        }
    }
}
