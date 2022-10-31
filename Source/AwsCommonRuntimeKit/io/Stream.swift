//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo
import Foundation

public protocol AwsStream {
    var isEndOfStream: Bool { get }
    var length: UInt { get }

    func seek(offset: Int64, basis: aws_stream_seek_basis) -> Bool
    func read(buffer: inout aws_byte_buf) -> Bool
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
    public func seek(offset: Int64, basis: aws_stream_seek_basis) -> Bool {
        let targetOffset: UInt64
        if basis.rawValue == AWS_SSB_BEGIN.rawValue {
            targetOffset = self.offsetInFile + UInt64(offset)
        } else {
            targetOffset = self.offsetInFile - UInt64(offset)
        }
        self.seek(toFileOffset: targetOffset)
        return true
    }

    @inlinable
    public func read(buffer: inout aws_byte_buf) -> Bool {
        let data = self.readData(ofLength: buffer.capacity - buffer.len)
        if data.count > 0 {
            let result = buffer.buffer.advanced(by: buffer.len)
            data.copyBytes(to: result, count: data.count)
            buffer.len += data.count
            return true
        }
        return !isEndOfStream
    }
}
