//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo
import Foundation

public protocol IStreamable {
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
    public func length() throws -> UInt64 {
        let length: UInt64
        let savedPos: UInt64
        if #available(macOS 11, *) {
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
    public func read(buffer: UnsafeMutablePointer<UInt8>, maxLength: Int) throws -> Int {
        let data: Data?
        if #available(macOS 11, *) {
            data = try self.read(upToCount: maxLength)
        } else {
            data = self.readData(ofLength: maxLength)
        }
        guard let data = data else {
            return 0
        }
        if data.count > 0 {
            data.copyBytes(to: buffer, count: data.count)
        }
        return data.count
    }
}
