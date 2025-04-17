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

    /// Write data up to `buffer.count` and returns the number of bytes written.
    /// buffer.count must not be modified.
    ///
    /// - Parameters:
    ///     - buffer: The buffer to write data to.
    /// - Returns: `nil` if the end of the file has been reached.
    ///   Returns `0` if the data is not yet available.
    ///   Otherwise returns the number of bytes read.
    func read(buffer: UnsafeMutableBufferPointer<UInt8>) throws -> Int?
    
    func isEndOfStream() -> Bool
}

public extension IStreamable {

    func seek(offset: UInt64, streamSeekType: StreamSeekType) throws {
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
            savedPos = try offset()
            try seekToEnd()
            length = try offset()
        } else {
            savedPos = offsetInFile
            seekToEndOfFile()
            length = offsetInFile
        }
        guard length != savedPos else {
            return length
        }
        try self.seek(toOffset: savedPos)
        return length
    }

    public func seek(offset: Int64, streamSeekType: StreamSeekType) throws {
        let targetOffset: UInt64
        switch streamSeekType {
        case .begin:
            guard offset >= 0 else {
                throw CommonRunTimeError.crtError(CRTError(code: AWS_IO_STREAM_INVALID_SEEK_POSITION.rawValue))
            }
            targetOffset = UInt64(offset)
        case .end:
            guard offset != 0 else {
                if #available(macOS 11, tvOS 13.4, iOS 13.4, watchOS 6.2, *) {
                    try seekToEnd()
                } else {
                    seekToEndOfFile()
                }
                return
            }
            let length = try length()
            guard offset <= 0, abs(offset) <= length else {
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

        if !data.isEmpty {
            data.copyBytes(to: buffer, from: 0..<data.count)
        }
        return data.count
    }
    
    public func isEndOfStream() -> Bool {
        return false
    }
}
