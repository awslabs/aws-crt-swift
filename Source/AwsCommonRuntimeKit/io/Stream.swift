//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AwsCIo
import Foundation

// swiftlint:disable trailing_whitespace

private var vtable = aws_input_stream_vtable(seek: doSeek,
                                             read: doRead,
                                             get_status: doGetStatus,
                                             get_length: doGetLength,
                                             acquire: { _ = Unmanaged<AwsInputStream>.fromOpaque($0!.pointee.impl).retain() },
                                             release: { Unmanaged<AwsInputStream>.fromOpaque($0!.pointee.impl).release() })

public class AwsInputStream {
    var rawValue: aws_input_stream
    let awsStream: AwsStream
    public var length: Int64
    public init(_ impl: AwsStream, allocator _: Allocator = defaultAllocator) {
        self.length = Int64(impl.length)
        self.awsStream = impl
        self.rawValue = aws_input_stream()
        rawValue.vtable = UnsafePointer<aws_input_stream_vtable>(&vtable)
        rawValue.impl = Unmanaged<AwsInputStream>.passUnretained(self).toOpaque()
    }
}

public protocol AwsStream {
    var status: aws_stream_status { get }
    var length: UInt { get }

    func seek(offset: Int64, basis: aws_stream_seek_basis) -> Bool
    func read(buffer: inout aws_byte_buf) -> Bool
}

extension FileHandle: AwsStream {
    @inlinable
    public var status: aws_stream_status {
        aws_stream_status(is_end_of_stream: length == offsetInFile, is_valid: true)
    }

    @inlinable
    public var length: UInt {
        let savedPos = offsetInFile
        defer { self.seek(toFileOffset: savedPos) }
        seekToEndOfFile()
        return UInt(offsetInFile)
    }

    @inlinable
    public func seek(offset: Int64, basis: aws_stream_seek_basis) -> Bool {
        let targetOffset: UInt64
        if basis.rawValue == AWS_SSB_BEGIN.rawValue {
            targetOffset = offsetInFile + UInt64(offset)
        } else {
            targetOffset = offsetInFile - UInt64(offset)
        }
        seek(toFileOffset: targetOffset)
        return true
    }

    @inlinable
    public func read(buffer: inout aws_byte_buf) -> Bool {
        let data = readData(ofLength: buffer.capacity - buffer.len)
        if !data.isEmpty {
            let result = buffer.buffer.advanced(by: buffer.len)
            data.copyBytes(to: result, count: data.count)
            buffer.len += data.count
            return true
        }
        return !status.is_end_of_stream
    }
}

private func doSeek(_ stream: UnsafeMutablePointer<aws_input_stream>!,
                    _ offset: Int64,
                    _ seekBasis: aws_stream_seek_basis) -> Int32 {
    let inputStream = Unmanaged<AwsInputStream>.fromOpaque(stream.pointee.impl).takeUnretainedValue()
    if inputStream.awsStream.seek(offset: offset, basis: seekBasis) {
        return AWS_OP_SUCCESS
    }
    return AWS_OP_ERR
}

private func doRead(_ stream: UnsafeMutablePointer<aws_input_stream>!,
                    _ buffer: UnsafeMutablePointer<aws_byte_buf>!) -> Int32 {
    let inputStream = Unmanaged<AwsInputStream>.fromOpaque(stream.pointee.impl).takeUnretainedValue()
    if inputStream.awsStream.read(buffer: &buffer.pointee) {
        return AWS_OP_SUCCESS
    }
    return AWS_OP_ERR
}

private func doGetStatus(_ stream: UnsafeMutablePointer<aws_input_stream>!,
                         _ result: UnsafeMutablePointer<aws_stream_status>!) -> Int32 {
    let inputStream = Unmanaged<AwsInputStream>.fromOpaque(stream.pointee.impl).takeUnretainedValue()
    result.pointee = inputStream.awsStream.status
    return AWS_OP_SUCCESS
}

private func doGetLength(_ stream: UnsafeMutablePointer<aws_input_stream>!,
                         _ result: UnsafeMutablePointer<Int64>!) -> Int32 {
    let inputStream = Unmanaged<AwsInputStream>.fromOpaque(stream.pointee.impl).takeUnretainedValue()
    let length = inputStream.awsStream.length

    result.pointee = Int64(length)
    return AWS_OP_SUCCESS
}
