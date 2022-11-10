//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo
import Foundation

public protocol AwsStream {
    var isEndOfStream: Bool { get }
    var length: UInt { get }

    func seek(offset: Int64, streamSeekType: StreamSeekType) -> Bool
    /// Data.count should not greater than length.
    func read(length: Int) -> Data
}

/// Direction to seek the stream.
public enum StreamSeekType: UInt32 {
    /// Seek the stream starting from beginning
    case begin = 0
    /// Seek the stream from End.
    case end = 2
}

public class AwsInputStream {
    public var length: Int64
    let awsInputStreamCore: AwsInputStreamCore
    public init(_ impl: AwsStream, allocator: Allocator = defaultAllocator) {
        length = Int64(impl.length)
        awsInputStreamCore = AwsInputStreamCore(awsStream: impl, allocator: allocator)
    }
}

extension FileHandle: AwsStream {
    @inlinable
    public var isEndOfStream: Bool {
        self.length == self.offsetInFile
    }

    @inlinable
    public var length: UInt {
        let savedPos = self.offsetInFile
        defer { self.seek(toFileOffset: savedPos ) }
        self.seekToEndOfFile()
        return UInt(self.offsetInFile)
    }

    @inlinable
    public func seek(offset: Int64, streamSeekType: StreamSeekType) -> Bool {
        let targetOffset: UInt64
        switch streamSeekType {
        case .begin: targetOffset = self.offsetInFile + UInt64(offset)
        case .end: targetOffset = self.offsetInFile - UInt64(offset)
        }
        self.seek(toFileOffset: targetOffset)
        return true
    }

    @inlinable
    public func read(length: Int) -> Data {
        return self.readData(ofLength: length)
    }
}
