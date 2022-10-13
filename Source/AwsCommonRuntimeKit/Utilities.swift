//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCIo
import struct Foundation.Date
import struct Foundation.Data
import class Foundation.FileHandle
import AwsCCommon
import AwsCCal

@inlinable
func zeroStruct<T>(_ ptr: UnsafeMutablePointer<T>) {
    memset(ptr, 0x00, MemoryLayout<T>.size)
}

extension Data {
    @inlinable
    var awsByteCursor: aws_byte_cursor {
        return withUnsafeBytes { (rawPtr: UnsafeRawBufferPointer) -> aws_byte_cursor in
            return aws_byte_cursor_from_array(rawPtr.baseAddress, self.count)
        }
    }
}

extension String {

    public func base64EncodedMD5(allocator: Allocator = defaultAllocator, truncate: Int = 0) -> String? {
        let bufferPtr: UnsafeMutablePointer<UInt8> = allocator.allocate(capacity: 16)
        var buffer = aws_byte_buf(len: 0, buffer: bufferPtr, capacity: 16, allocator: allocator.rawValue)
        guard self.withByteCursorPointer({ strCursorPointer in
           aws_md5_compute(allocator.rawValue, strCursorPointer, &buffer, truncate)
        }) == AWS_OP_SUCCESS else {
            return nil
        }
        let result =  Data(bytesNoCopy: bufferPtr, count: 16, deallocator: .none).base64EncodedString()
        allocator.release(bufferPtr)
        return result
    }

    func withByteCursor<R>(_ body: (aws_byte_cursor) -> R
    ) -> R {
        return self.withCString { arg1C in
            return body(aws_byte_cursor_from_c_str(arg1C))
        }
    }

    func withByteCursorPointer<R>(_ body: (UnsafePointer<aws_byte_cursor>) -> R
    ) -> R {
        return self.withCString { arg1C in
            return withUnsafePointer(to: aws_byte_cursor_from_c_str(arg1C)) { byteCursorPointer in
                return body(byteCursorPointer)
            }
        }
    }
}

extension aws_byte_buf {
    func toByteBuffer() -> ByteBuffer {
        return ByteBuffer(ptr: self.buffer, len: self.len, capacity: self.capacity)
    }
}

extension aws_array_list {
    func toStringArray() -> [String] {
        let length = self.length
        var arrayList = self
        var newArray: [String] = Array(repeating: "", count: length)

        for index  in 0..<length {
            var val: UnsafeMutableRawPointer! = nil
            aws_array_list_get_at(&arrayList, &val, index)
            newArray[index] = val.bindMemory(to: String.self, capacity: 1).pointee
        }

        return newArray
    }
}

public extension Int32 {
    func toString() -> String? {
        // Convert UnicodeScalar to a String.
        if let unicodeScalar = UnicodeScalar(Int(self)) {
            return String(unicodeScalar)
        }
        return nil
    }
}

extension UnsafeMutablePointer {
    func deinitializeAndDeallocate() {
        self.deinitialize(count: 1)
        self.deallocate()
    }
}

extension Date {
    var awsDateTime: aws_date_time {
        let datefrom1970 = UInt64(self.timeIntervalSince1970 * 1000)
        let dateTime = AWSDate(epochMs: datefrom1970)
        return dateTime.rawValue.pointee
    }
}

extension Bool {
    var uintValue: UInt32 {
        return self ? 1 : 0
    }
}

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

func withByteCursorFromStrings<R>(
        _ arg1: String, _ arg2: String, _ body: (aws_byte_cursor, aws_byte_cursor) -> R
) -> R {
    return arg1.withCString { arg1C in
        return arg2.withCString { arg2C in
                return body(aws_byte_cursor_from_c_str(arg1C), aws_byte_cursor_from_c_str(arg2C))
        }
    }
}

func withByteCursorFromStrings<R>(
        _ arg1: String, _ arg2: String, _ arg3: String, _ body: (aws_byte_cursor, aws_byte_cursor, aws_byte_cursor) -> R
) -> R {
    return arg1.withCString { arg1C in
        return arg2.withCString { arg2C in
            return arg3.withCString {arg3c in
                return body(aws_byte_cursor_from_c_str(arg1C), aws_byte_cursor_from_c_str(arg2C), aws_byte_cursor_from_c_str(arg3c))
            }
        }
    }
}
