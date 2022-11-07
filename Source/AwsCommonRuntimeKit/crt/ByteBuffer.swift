//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import struct Foundation.Data
import class Foundation.InputStream
import class Foundation.FileManager
import class Foundation.FileHandle
import class Foundation.OutputStream
import struct Foundation.URL
import AwsCIo
import AwsCCommon
import AwsCCal
#if os(Linux)
     import Glibc
 #else
     import Darwin
 #endif

public class ByteBuffer: Codable {

    public init(size: Int) {
        array.reserveCapacity(size)
        self.capacity = size
    }

    public init(bytes: [UInt8]) {
        self.array = bytes
        self.capacity = bytes.count
    }

    public init(ptr: UnsafeMutablePointer<UInt8>, len: Int, capacity: Int) {
        let buffer = UnsafeBufferPointer(start: ptr, count: len)
        self.array = Array(buffer)
        self.capacity = capacity
    }

    public func allocate(_ size: Int) {
        array = [UInt8]()
        array.reserveCapacity(size)
        self.capacity += size
        currentIndex = 0
    }

    public func nativeByteOrder() -> Endianness {
        return hostEndianness
    }

    public func currentByteOrder() -> Endianness {
        return currentEndianness
    }

    public func order(_ endianness: Endianness) -> ByteBuffer {
        currentEndianness = endianness
        return self
    }

    public func putByte(_ value: UInt8) {
        array.append(value)
    }

    public func put(_ value: UInt8) -> ByteBuffer {
        array.append(value)
        return self
    }

    public func put(_ value: [UInt8]) -> ByteBuffer {
        array.append(contentsOf: value)
        return self
    }

    public func put(_ value: ByteBuffer, offset: UInt = 0, maxBytes: UInt? = nil) {
        var end: UInt = UInt(value.length)
        if let maxBytes = maxBytes {
             end = maxBytes
        }
        let bytesToTake = value.array[Int(offset)..<Int(end)]
        array.append(contentsOf: bytesToTake)
    }

    public func put(_ value: Data) {
        let byteArray: [UInt8] = value.map { $0 }
        array.append(contentsOf: byteArray)
    }

    public func put(_ value: Int32) -> ByteBuffer {
        if currentEndianness == .little {
            array.append(contentsOf: to(value.littleEndian))
            return self
        }
        let arrayOfBytes = to(value.bigEndian)
        array.append(contentsOf: arrayOfBytes)

        return self
    }

    public func put(_ value: Int64) -> ByteBuffer {
        if currentEndianness == .little {
            array.append(contentsOf: to(value.littleEndian))
            return self
        }
        let arrayOfBytes = to(value.bigEndian)
        array.append(contentsOf: arrayOfBytes)

        return self
    }

    public func put(_ value: Int) -> ByteBuffer {
        if currentEndianness == .little {
            array.append(contentsOf: to(value.littleEndian))
            return self
        }

        let arrayOfBytes = to(value.bigEndian)
        array.append(contentsOf: arrayOfBytes)
        return self
    }

    public func put(_ value: Float) -> ByteBuffer {
        if currentEndianness == .little {
            array.append(contentsOf: to(value.bitPattern.littleEndian))
            return self
        }
        let arrayOfBytes = to(value.bitPattern.bigEndian)
        array.append(contentsOf: arrayOfBytes)

        return self
    }

    public func put(_ value: Double) -> ByteBuffer {
        if currentEndianness == .little {
            array.append(contentsOf: to(value.bitPattern.littleEndian))
            return self
        }
        let arrayOfBytes = to(value.bitPattern.bigEndian)
        array.append(contentsOf: arrayOfBytes)

        return self
    }

    public func get() -> UInt8 {
        let result = array[currentIndex]
        currentIndex += 1
        return result
    }

    public func get(_ index: Int) -> UInt8 {
        return array[index]
    }

    public func getInt32() -> Int32 {
        let result = from(Array(array[currentIndex..<currentIndex + MemoryLayout<Int32>.size]), Int32.self)
        currentIndex += MemoryLayout<Int32>.size
        return currentEndianness == .little ? result.littleEndian : result.bigEndian
    }

    public func getInt32(_ index: Int) -> Int32 {
        let result = from(Array(array[index..<index + MemoryLayout<Int32>.size]), Int32.self)
        return currentEndianness == .little ? result.littleEndian : result.bigEndian
    }

    public func getInt64() -> Int64 {
        let result = from(Array(array[currentIndex..<currentIndex + MemoryLayout<Int64>.size]), Int64.self)
        currentIndex += MemoryLayout<Int64>.size
        return currentEndianness == .little ? result.littleEndian : result.bigEndian
    }

    public func getInt64(_ index: Int) -> Int64 {
        let result = from(Array(array[index..<index + MemoryLayout<Int64>.size]), Int64.self)
        return currentEndianness == .little ? result.littleEndian : result.bigEndian
    }

    public func getInt() -> Int {
        let result = from(Array(array[currentIndex..<currentIndex + MemoryLayout<Int>.size]), Int.self)
        currentIndex += MemoryLayout<Int>.size
        return currentEndianness == .little ? result.littleEndian : result.bigEndian
    }

    public func getInt(_ index: Int) -> Int {
        let result = from(Array(array[index..<index + MemoryLayout<Int>.size]), Int.self)
        return currentEndianness == .little ? result.littleEndian : result.bigEndian
    }

    public func getFloat() -> Float {
        let result = from(Array(array[currentIndex..<currentIndex + MemoryLayout<UInt32>.size]), UInt32.self)
        currentIndex += MemoryLayout<UInt32>.size
        return currentEndianness == .little ? Float(bitPattern: result.littleEndian)
            : Float(bitPattern: result.bigEndian)
    }

    public func getFloat(_ index: Int) -> Float {
        let result = from(Array(array[index..<index + MemoryLayout<UInt32>.size]), UInt32.self)
        return currentEndianness == .little ? Float(bitPattern: result.littleEndian)
            : Float(bitPattern: result.bigEndian)
    }

    public func getDouble() -> Double {
        let result = from(Array(array[currentIndex..<currentIndex + MemoryLayout<UInt64>.size]), UInt64.self)
        currentIndex += MemoryLayout<UInt64>.size
        return currentEndianness == .little ? Double(bitPattern: result.littleEndian)
            : Double(bitPattern: result.bigEndian)
    }

    public func getDouble(_ index: Int) -> Double {
        let result = from(Array(array[index..<index + MemoryLayout<UInt64>.size]), UInt64.self)
        return currentEndianness == .little ? Double(bitPattern: result.littleEndian)
            : Double(bitPattern: result.bigEndian)
    }

    public func toByteArray() -> [UInt8] {
        return array
    }

    public enum Endianness {
        case little
        case big
    }

    private func to<T>(_ value: T) -> [UInt8] {
        var value = value
        return withUnsafeBytes(of: &value, Array.init)
    }

    private func from<T>(_ value: [UInt8], _: T.Type) -> T {
        return value.withUnsafeBytes {
            $0.load(fromByteOffset: 0, as: T.self)
        }
    }

    private var array = [UInt8]()
    private var currentIndex: Int = 0
    var capacity: Int = 0

    private var currentEndianness: Endianness = .big
    private var hostEndianness: Endianness {
        let number: UInt32 = 0x12345678
        return number == number.bigEndian ? .big : .little
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(array)
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        array = try container.decode([UInt8].self)
    }

    public func readIntoBuffer(buffer: inout ByteBuffer) -> Int {
        guard !array.isEmpty else {
            return 0
        }

        guard currentIndex < array.count else {
            return 0
        }
        let bufferCapacity = buffer.capacity - buffer.array.count
        var arrayEnd = array.count > bufferCapacity ? bufferCapacity + currentIndex: array.count
        if arrayEnd > array.count {
            arrayEnd = array.count
        }
        let dataArray = Array(array[currentIndex..<(arrayEnd)])
        if !dataArray.isEmpty {
            _ = buffer.put(dataArray)
            self.currentIndex = arrayEnd
            return dataArray.count
        } else {
            return 0
        }
    }
}

extension ByteBuffer: AwsStream {
    public var status: aws_stream_status {
        return aws_stream_status(is_end_of_stream: self.currentIndex == array.count, is_valid: true)
    }

    public var length: UInt {
        return UInt(array.count)
    }

    public func seek(offset: Int64, basis: aws_stream_seek_basis) -> Bool {
        let targetOffset: Int64
        if basis.rawValue == AWS_SSB_BEGIN.rawValue {
            targetOffset = offset

        } else {
            targetOffset = Int64(length) - offset
        }
        currentIndex = Int(targetOffset)
        return true
    }

    public func read(buffer: inout aws_byte_buf) -> Bool {
        let bufferCapacity = buffer.capacity - buffer.len
        let arrayEnd = (bufferCapacity + self.currentIndex) < array.count
        ? bufferCapacity + self.currentIndex
        : array.count
        let dataArray = array[self.currentIndex..<(arrayEnd)]
        if !dataArray.isEmpty {
            let result = buffer.buffer.advanced(by: buffer.len)
            let resultBufferPointer = UnsafeMutableBufferPointer.init(start: result, count: dataArray.count)
            dataArray.copyBytes(to: resultBufferPointer)
            self.currentIndex = arrayEnd
            buffer.len += dataArray.count
            return true
        }
        return !self.status.is_end_of_stream
    }
}

extension ByteBuffer {
    /// initialize a  new `ByteBuffer` instance from `Foundation.Data`
    public convenience init(data: Data) {
        self.init(size: data.count)
        put(data)
    }

    /// initialize a new `ByteBuffer` instance from `Foundation.InputStream`
    public convenience init(stream: InputStream) throws {
        self.init(size: 0)
        stream.open()
        defer {
            stream.close()
        }

        let bufferSize = 1024
        let buffer: UnsafeMutablePointer<UInt8> = allocatePointer(bufferSize)
        defer {
            buffer.deallocate()
        }

        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            if read < 0 {
                // Stream error occured
                throw stream.streamError!
            } else if read == 0 {
                // EOF
                break
            }
            allocate(read)
            putByte(buffer.pointee)
        }
    }

    /// initialize a new `ByteBuffer` instance from a file path in the format of a `String`
    public convenience init(filePath: String) throws {
        let url = URL(fileURLWithPath: filePath)

        let data = try Data(contentsOf: url)

        self.init(data: data)
    }

    /// Coverts the array of bytes to a `Data` object
    ///
    /// - Returns: `Data`
    public func toData() -> Data {
        return Data(bytes: array, count: array.count)
    }

    /// Creates a new file at the `filePath` given and writes the data to it returning a `FileHandle` to it.
    ///
    /// - Parameters:
    ///   - filePath:  The path at which you would like a new file to be created at and written to.
    /// - Returns: `FileHandle`
    public func toFile(filePath: String) -> FileHandle? {
        let fileManager = FileManager.default
        if fileManager.createFile(atPath: filePath, contents: self.toData()) {
            return FileHandle(forReadingAtPath: filePath)
        } else {
            return nil
        }
    }

    /// Converts the array of bytes to `Foundation.InputStream`
    ///
    /// - Returns: `InputStream`
    public func toStream() -> InputStream {
        return InputStream(data: self.toData())
    }

    func toAwsByteBuf(allocator: Allocator = defaultAllocator) -> aws_byte_buf {
        let count = self.array.count
        return self.array.withUnsafeMutableBufferPointer { pointer in
            return aws_byte_buf(len: count,
                                buffer: pointer.baseAddress,
                                capacity: capacity,
                                allocator: allocator.rawValue)
        }
    }
}

public extension ByteBuffer {
    func sha256(allocator: Allocator = defaultAllocator, truncate: Int = 0) -> ByteBuffer {
        var byteCursor = aws_byte_cursor_from_array(self.array, self.array.count)

        var bytes = [UInt8](repeating: 0, count: Int(AWS_SHA256_LEN))
        let result: ByteBuffer = bytes.withUnsafeMutableBufferPointer { pointer in
            var buffer = aws_byte_buf(
                len: 0,
                buffer: pointer.baseAddress,
                capacity: Int(AWS_SHA256_LEN),
                allocator: allocator.rawValue
            )
            aws_sha256_compute(allocator.rawValue, &byteCursor, &buffer, truncate)
            return buffer.toByteBuffer()
        }
        return result
    }

    func base64EncodedSha256(allocator: Allocator = defaultAllocator, truncate: Int = 0) -> String {
        return sha256(allocator: allocator, truncate: truncate).toData().base64EncodedString()
    }

    func encodeToHexString() -> String {
        var hexString = ""
        for byte in array {
            hexString += String(format: "%02x", UInt8(byte))
        }

        return hexString
    }
}
