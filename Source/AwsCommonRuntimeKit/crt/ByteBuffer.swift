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

public class ByteBuffer: Codable {

    private var data: Data
    private var currentIndex: Data.Index

    public init(size: Int) {
        data = Data(capacity: size)
        currentIndex = data.startIndex
    }

    public init(bytes: [UInt8]) {
        self.data = Data(bytes)
        currentIndex = data.startIndex
    }

    public init(data: Data) {
        self.data = data
        currentIndex = data.startIndex
    }

    public init(bufferPointer: UnsafeMutablePointer<UInt8>, length: Int, capacity: Int) {
        self.data = Data(bytes: bufferPointer, count: capacity)
        currentIndex = data.startIndex
    }

    public func put(_ value: UInt8) {
        data.append(value)
    }

    public func put(_ value: [UInt8])  {
        data.append(contentsOf: value)
    }

    public func put(buffer: ByteBuffer, offset: UInt = 0, maxBytes: UInt? = nil) {
        //TODO: verify if maxBytes > buffer size
        var end: UInt = UInt(buffer.data.count)
        if let maxBytes = maxBytes {
            end = maxBytes
        }
        data.append(contentsOf: buffer.data.subdata(in: Int(offset)..<Int(end)))
    }

    public func put(_ value: Data) {
        data.append(value)
    }

    public func getData() -> Data {
        return data
    }

}

extension ByteBuffer: IStreamable {

    public func length() -> UInt64 {
        return UInt64(data.count)
    }

    public func seek(offset: Int64, streamSeekType: StreamSeekType) throws {
        if abs(offset) > data.count
                   || (offset < 0 && streamSeekType == .begin)
                   || (offset > 0 && streamSeekType == .end) {
            throw CommonRunTimeError.crtError(CRTError(code: AWS_IO_STREAM_INVALID_SEEK_POSITION.rawValue))
        }

        switch streamSeekType {
        case .begin:
            currentIndex = Int(offset)
        case .end:
            currentIndex = data.count + Int(offset)
        }
    }

    public func read(buffer: UnsafeMutableBufferPointer<UInt8>) -> Int? {
        let endIndex = currentIndex + min(data.count - currentIndex, buffer.count)
        guard currentIndex != endIndex else {
            return nil
        }

        let dataArray = data[currentIndex..<endIndex]
        dataArray.copyBytes(to: buffer, count: dataArray.count)
        currentIndex = endIndex
        return dataArray.count
    }
}

public extension ByteBuffer {
    // Used to calculate sha256
    func sha256(allocator: Allocator = defaultAllocator, truncate: Int = 0) -> ByteBuffer {
        data.withUnsafeBytes { bufferPointer in
            var byteCursor = aws_byte_cursor_from_array(bufferPointer.baseAddress, self.data.count)
            let length = Int(AWS_SHA256_LEN)
            var bytes = [UInt8](repeating: 0, count: length)
            let result: ByteBuffer = bytes.withUnsafeMutableBufferPointer { pointer in
                var buffer = aws_byte_buf_from_empty_array(pointer.baseAddress, length)
                aws_sha256_compute(allocator.rawValue, &byteCursor, &buffer, truncate)
                return buffer.toByteBuffer()
            }
            return result
        }
    }

    func base64EncodedSha256(allocator: Allocator = defaultAllocator, truncate: Int = 0) -> String {
        return sha256(allocator: allocator, truncate: truncate).getData().base64EncodedString()
    }

    //used, ByteBuffer(data: data).sha256().encodeToHexString()
    func encodeToHexString() -> String {
        var hexString = ""
        for byte in data {
            hexString += String(format: "%02x", UInt8(byte))
        }

        return hexString
    }
}
