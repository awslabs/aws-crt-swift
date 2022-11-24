//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCIo
import struct Foundation.Date
import struct Foundation.Data
import class Foundation.FileHandle
import struct Foundation.TimeInterval
import AwsCCommon
import AwsCCal

@inlinable
func zeroStruct<T>(_ ptr: UnsafeMutablePointer<T>) {
    memset(ptr, 0x00, MemoryLayout<T>.size)
}

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

//Todo: refactor
extension aws_byte_buf {
    func toByteBuffer() -> ByteBuffer {
        return ByteBuffer(ptr: self.buffer, len: self.len, capacity: self.capacity)
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
            result.append(byteCursor.toString()!)
        }
        return result
    }
}

//Todo: refactor
public extension Int32 {
    func toString() -> String? {
        // Convert UnicodeScalar to a String.
        if let unicodeScalar = UnicodeScalar(Int(self)) {
            return String(unicodeScalar)
        }
        return nil
    }
}

//Todo: remove these pointers functions and use aws_allocator
extension UnsafeMutablePointer {
    func deinitializeAndDeallocate() {
        self.deinitialize(count: 1)
        self.deallocate()
    }
}

extension Bool {
    var uintValue: UInt32 {
        return self ? 1 : 0
    }
}

//Todo: remove these pointers functions and use aws_allocator
// Ensure that any UnsafeXXXPointer is ALWAYS initialized to either nil or a value in a single call. Prevents the
// case where you create an UnsafeMutableWhatever and do not call `initialize()` on it, resulting in a non-null but
// also invalid pointer
func fromPointer<T, P: PointerConformance>(ptr: T) -> P {
    let pointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
    pointer.initialize(to: ptr)
    return P(OpaquePointer(pointer))
}

func fromOptionalPointer<T, P: PointerConformance>(ptr: T?) -> P? {
    if let ptr = ptr {
        return fromPointer(ptr: ptr)
    }
    return nil
}

func allocatePointer<T>(_ capacity: Int = 1) -> UnsafeMutablePointer<T> {
    let ptr = UnsafeMutablePointer<T>.allocate(capacity: capacity)
    zeroStruct(ptr)
    return ptr
}

func toPointerArray<T, P: PointerConformance>(_ array: [T]) -> P {
    let pointers = UnsafeMutablePointer<T>.allocate(capacity: array.count)

    for index in 0..<array.count {
        pointers.advanced(by: index).initialize(to: array[index])
    }
    return P(OpaquePointer(pointers))
}

protocol PointerConformance {
    init(_ pointer: OpaquePointer)
}

extension UnsafeMutablePointer: PointerConformance {}

extension UnsafeMutableRawPointer: PointerConformance {}

extension UnsafePointer: PointerConformance {}

extension UnsafeRawPointer: PointerConformance {}

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
