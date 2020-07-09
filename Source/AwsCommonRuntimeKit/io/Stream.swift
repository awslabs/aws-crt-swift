//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo
import Foundation

fileprivate var vtable = aws_input_stream_vtable(seek: doSeek, read: doRead, get_status: doGetStatus, get_length: doGetLength, destroy: doDestroy)

public class AwsInputStream {
    internal var rawValue: aws_input_stream

    internal init(_ impl: inout AwsInputStreamImpl, allocator: Allocator) {
        self.rawValue = aws_input_stream(allocator: allocator.rawValue, impl: &impl, vtable: &vtable)
    }
}

public protocol AwsInputStreamImpl {
    var status: aws_stream_status { get }
    var length: Int64 { get }

    func seek(offset: aws_off_t, basis: aws_stream_seek_basis) -> Bool
    func read(buffer: inout aws_byte_buf) -> Bool
}

extension FileHandle : AwsInputStreamImpl {
    @inlinable
    public var status: aws_stream_status {
        // TODO: Is this way to get is_end_of_stream safe?
        return aws_stream_status(is_end_of_stream: self.length == self.offsetInFile, is_valid: true)
    }

    @inlinable
    public var length: Int64 {
        let savedPos = self.offsetInFile
        defer { self.seek(toFileOffset: savedPos ) }
        self.seekToEndOfFile()
        // TODO: What happens if the UInt64 is > Int64.max ??
        return Int64(self.offsetInFile)
    }

    @inlinable
    public func seek(offset: aws_off_t, basis: aws_stream_seek_basis) -> Bool {
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
        return !self.status.is_end_of_stream
    }
}

private func doSeek(_ stream: UnsafeMutablePointer<aws_input_stream>!, _ offset: aws_off_t, _ seekBasis: aws_stream_seek_basis) -> Int32 {
    let inputStream = stream.pointee.impl.bindMemory(to: AwsInputStreamImpl.self, capacity: 1).pointee
    if inputStream.seek(offset: offset, basis: seekBasis) {
        return AWS_OP_SUCCESS
    }
    return AWS_OP_ERR
}

private func doRead(_ stream: UnsafeMutablePointer<aws_input_stream>!, _ buffer: UnsafeMutablePointer<aws_byte_buf>!) -> Int32 {
    let inputStream = stream.pointee.impl.bindMemory(to: AwsInputStreamImpl.self, capacity: 1).pointee
    if inputStream.read(buffer: &buffer.pointee) {
        return AWS_OP_SUCCESS
    }
    return AWS_OP_ERR
}

private func doGetStatus(_ stream: UnsafeMutablePointer<aws_input_stream>!, _ result: UnsafeMutablePointer<aws_stream_status>!) -> Int32 {
    let inputStream = stream.pointee.impl.bindMemory(to: AwsInputStreamImpl.self, capacity: 1).pointee
    result.pointee = inputStream.status
    return AWS_OP_SUCCESS
}

private func doGetLength(_ stream: UnsafeMutablePointer<aws_input_stream>!, _ result: UnsafeMutablePointer<Int64>!) -> Int32 {
    let inputStream = stream.pointee.impl.bindMemory(to: AwsInputStreamImpl.self, capacity: 1).pointee
    let length = inputStream.length
    if (length >= 0) {
        result.pointee = length
        return AWS_OP_SUCCESS
    }
    aws_raise_error(Int32(AWS_IO_STREAM_READ_FAILED.rawValue))
    return AWS_OP_ERR
}

private func doDestroy(_ stream: UnsafeMutablePointer<aws_input_stream>!) -> Void {
    // Nothing to do!
}
