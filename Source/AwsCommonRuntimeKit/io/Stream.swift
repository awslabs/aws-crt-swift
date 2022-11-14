//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo
import Foundation

public protocol IStreamable {

    /// Optional, throws length not supported error by default
    func length() throws -> UInt64

    /// (Optional) throws Seek not supported error by default.
    func seek(offset: UInt64) throws

    /// buffer count should not be modified.
    func read(buffer: UnsafeMutableBufferPointer<UInt8>) throws -> Int
}

extension IStreamable {

    func seek(offset: UInt64) throws {
        throw CommonRunTimeError.crtError(CRTError(code: Int32(AWS_IO_STREAM_SEEK_UNSUPPORTED.rawValue)))
    }

    func length() throws -> UInt64 {
        throw CommonRunTimeError.crtError(CRTError(code: Int32(AWS_IO_STREAM_GET_LENGTH_UNSUPPORTED.rawValue)))
    }
}

/// Direction to seek the stream.
enum StreamSeekType: UInt32 {
    /// Seek the stream starting from beginning
    case begin = 0
    /// Seek the stream from End.
    case end = 2
}

extension FileHandle: IStreamable {

    @inlinable
    public func length() throws -> UInt64 {
        let length: UInt64
        let savedPos: UInt64
        if #available(macOS 11, tvOS 13.4, iOS 13.4, watchOS 6.2, *) {
            savedPos = try self.offset()
            try self.seekToEnd()
            length = try self.offset()
        } else {
            savedPos = self.offsetInFile
            self.seekToEndOfFile()
            length = self.offsetInFile
        }
        try self.seek(toOffset: savedPos)
        return length
    }

    @inlinable
    public func seek(offset: UInt64) throws {
        try self.seek(toOffset: offset)
    }

    @inlinable
    public func read(buffer: UnsafeMutableBufferPointer<UInt8>) throws -> Int {
        let data: Data?
        if #available(macOS 11, tvOS 13.4, iOS 13.4, watchOS 6.2, *) {
            data = try self.read(upToCount: buffer.count)
        } else {
            data = self.readData(ofLength: buffer.count)
        }
        guard let data = data else {
            return 0
        }

        guard let baseAddress = buffer.baseAddress else {
            throw CommonRunTimeError.crtError(CRTError(code: Int32(AWS_IO_STREAM_READ_FAILED.rawValue)))
        }

        if data.count > 0 {
            data.copyBytes(to: baseAddress, count: data.count)
        }
        return data.count
    }
}
