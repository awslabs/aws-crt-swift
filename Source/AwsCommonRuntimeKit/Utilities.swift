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
    @inlinable
    var awsByteCursor: aws_byte_cursor {
        return aws_byte_cursor_from_c_str(self.asCStr())
    }

    public func base64EncodedMD5(allocator: Allocator = defaultAllocator, truncate: Int = 0) -> String? {
        let input: UnsafePointer<aws_byte_cursor> = fromPointer(ptr: self.awsByteCursor)
        let emptyBuffer: UInt8 = 0
        let bufferPtr: UnsafeMutablePointer<UInt8> = fromPointer(ptr: emptyBuffer)
        let buffer = aws_byte_buf(len: 0, buffer: bufferPtr, capacity: 16, allocator: allocator.rawValue)
        let output: UnsafeMutablePointer<aws_byte_buf> = fromPointer(ptr: buffer)

        guard AWS_OP_SUCCESS == aws_md5_compute(allocator.rawValue, input, output, truncate) else {
            return nil
        }

        let byteCursor = aws_byte_cursor_from_buf(output)
        return byteCursor.toData().base64EncodedString()
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

    for index in 0...array.count {
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
