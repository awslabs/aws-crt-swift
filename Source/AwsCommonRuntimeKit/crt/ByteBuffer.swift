//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import struct Foundation.Data
import AwsCIo
import AwsCCal

public class ByteBuffer {

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

    public func put(_ value: [UInt8]) {
        data.append(contentsOf: value)
    }

    public func put(_ value: Data) {
        data.append(value)
    }

    public func getData() -> Data {
        return data
    }

    public func put(buffer: ByteBuffer, offset: UInt = 0, maxBytes: UInt? = nil) {
        guard offset < buffer.data.count else {
            return
        }
        let endIndex = offset + min(UInt(data.count) - offset, maxBytes ?? 0)
        data.append(contentsOf: buffer.data.subdata(in: Int(offset)..<Int(endIndex)))
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

        let subData = data.subdata(in: currentIndex..<endIndex)
        subData.copyBytes(to: buffer, count: subData.count)
        currentIndex = endIndex
        return subData.count
    }
}

extension ByteBuffer {
    func encodeToHexString() -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }
}
