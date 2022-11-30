//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import struct Foundation.Data
import AwsCIo
import AwsCCal

/// ByteBuffer represents a Data object with a current index and conforms to IStreamable protocol.
public final class ByteBuffer {

    private let data: Data
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
        let index: Int
        switch streamSeekType {
        case .begin:
            index = Int(offset)
        case .end:
            index = data.count + Int(offset)
        }
        currentIndex = data.index(data.startIndex, offsetBy: index)
    }

    public func read(buffer: UnsafeMutableBufferPointer<UInt8>) -> Int? {
        var endIndex = currentIndex
        _ = data.formIndex(&endIndex, offsetBy: buffer.count, limitedBy: data.endIndex)
        let dataSlice = data[currentIndex..<endIndex]
        guard dataSlice.count > 0 else {
            return nil
        }
        dataSlice.copyBytes(to: buffer, from: currentIndex..<endIndex)
        currentIndex = endIndex
        return dataSlice.count
    }
}

extension ByteBuffer {
    func encodeToHexString() -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }
}
