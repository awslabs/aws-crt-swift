//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo
import Foundation

public protocol IStreamable {
    func isEndOfStream() throws -> Bool
    func length() throws -> UInt64

    func seek(offset: UInt64) throws
    /// Data.count should not greater than length.
    func read(buffer: UnsafeMutablePointer<UInt8>, maxLength: Int) throws -> Int
}

/// Direction to seek the stream.
public enum StreamSeekType: UInt32 {
    /// Seek the stream starting from beginning
    case begin = 0
    /// Seek the stream from End.
    case end = 2
}

extension FileHandle: IStreamable {
    @inlinable
    public func isEndOfStream() throws -> Bool {
        return try self.length() == self.offset()
    }

    @inlinable
    public func length() throws -> UInt64 {
        let savedPos = try self.offset()
        defer {
            self.seek(toFileOffset: savedPos)
        }
        try self.seekToEnd()
        return try self.offset()
    }

    @inlinable
    public func seek(offset: UInt64) throws {
        try self.seek(toOffset: offset)
    }

    @inlinable
    public func read(buffer: UnsafeMutablePointer<UInt8>, maxLength: Int) throws -> Int {
        let data = try self.read(upToCount: maxLength)
        guard let data = data else {
            return 0
        }
        if data.count > 0 {
            data.copyBytes(to: buffer, count: data.count)
        }
        return data.count
    }
}
