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
    
    /// Whether the stream has ended. If the read function returns Nil that will also signify end of stream,
    /// so if your stream will never know in advance that it's ended and always requires an extra read to know the end, you can always return false from this method.
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
