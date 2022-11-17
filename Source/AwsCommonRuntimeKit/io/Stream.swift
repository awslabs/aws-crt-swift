//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo
import Foundation

/// This is for streaming input.
public protocol IStreamable {

    /// Optional, throws length not supported error by default
    func length() throws -> UInt64

    /// (Optional) Provides an implementation to seek the stream to a particular offset.
    ///
    /// - Parameters:
    ///   - offset: The value to set the seek position.
    ///             If the streamSeekType is .begin, offset value would be positive.
    ///             If the streamSeekType is .end, offset value would be negative.
    ///   - streamSeekType: The direction to seek the stream from
    /// - Throws: Throws Seek not supported error by default.
    func seek(offset: Int64, streamSeekType: StreamSeekType) throws

    /// Read up to buffer.count bytes into the buffer.
    /// buffer.count must not be modified.
    /// Return the number of bytes copied.
    /// Return nil if the end of file has been reached.
    /// Return 0 if data is not yet available.
    func read(buffer: UnsafeMutableBufferPointer<UInt8>) throws -> Int?
}

public extension IStreamable {

    func seek(offset: UInt64) throws {
        throw CommonRunTimeError.crtError(CRTError(code: Int32(AWS_IO_STREAM_SEEK_UNSUPPORTED.rawValue)))
    }

    func length() throws -> UInt64 {
        throw CommonRunTimeError.crtError(CRTError(code: Int32(AWS_IO_STREAM_GET_LENGTH_UNSUPPORTED.rawValue)))
    }
}

/// Direction to seek the stream.
public enum StreamSeekType: UInt32 {
    /// Seek the stream starting from beginning
    case begin = 0
    /// Seek the stream from End.
    case end = 2
}

extension FileHandle: IStreamable {

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

    public func seek(offset: Int64, streamSeekType: StreamSeekType) throws {
        let targetOffset: UInt64
        switch streamSeekType {
        case .begin:
            if offset < 0 {
                throw CommonRunTimeError.crtError(CRTError(code: AWS_IO_STREAM_INVALID_SEEK_POSITION.rawValue))
            }
            targetOffset = UInt64(offset)
        case .end:
            let length = try self.length()
            if offset > 0 || abs(offset) > length {
                throw CommonRunTimeError.crtError(CRTError(code: AWS_IO_STREAM_INVALID_SEEK_POSITION.rawValue))
            }
            targetOffset = length - UInt64(abs(offset))
        }
        try self.seek(toOffset: targetOffset)
    }

    public func read(buffer: UnsafeMutableBufferPointer<UInt8>) throws -> Int? {
        let data: Data?
        if #available(macOS 11, tvOS 13.4, iOS 13.4, watchOS 6.2, *) {
            data = try self.read(upToCount: buffer.count)
        } else {
            data = self.readData(ofLength: buffer.count)
        }
        guard let data = data else {
            return nil
        }

        if data.count > 0 {
            data.copyBytes(to: buffer, count: data.count)
        }
        return data.count
    }
}
