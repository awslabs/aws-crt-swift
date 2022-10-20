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

    public func base64EncodedMD5(allocator: Allocator = defaultAllocator, truncate: Int = 0) -> String? {
        var buffer = aws_byte_buf()
        if aws_byte_buf_init(&buffer, allocator.rawValue, 16) != AWS_OP_SUCCESS {
            return nil
        }
        guard self.withByteCursorPointer({ strCursorPointer in
           aws_md5_compute(allocator.rawValue, strCursorPointer, &buffer, truncate)
        }) == AWS_OP_SUCCESS else {
            return nil
        }
        return Data(bytesNoCopy: buffer.buffer, count: buffer.len, deallocator: .custom { _, _ in
            aws_byte_buf_clean_up(&buffer)
        }).base64EncodedString()
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

//Todo: refactor
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

func withByteCursorFromStrings<Result>(
        _ arg1: String, _ arg2: String, _ body: (aws_byte_cursor, aws_byte_cursor) -> Result
) -> Result {
    return arg1.withCString { arg1C in
        return arg2.withCString { arg2C in
                return body(aws_byte_cursor_from_c_str(arg1C), aws_byte_cursor_from_c_str(arg2C))
        }
    }
}

func withByteCursorFromStrings<Result>(
        _ arg1: String, _ arg2: String, _ arg3: String, _ body: (aws_byte_cursor, aws_byte_cursor, aws_byte_cursor) -> Result
) -> Result {
    return arg1.withCString { arg1C in
        return arg2.withCString { arg2C in
            return arg3.withCString {arg3c in
                return body(aws_byte_cursor_from_c_str(arg1C), aws_byte_cursor_from_c_str(arg2C), aws_byte_cursor_from_c_str(arg3c))
            }
        }
    }
}
