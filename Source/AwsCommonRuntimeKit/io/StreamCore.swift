//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

class AwsInputStreamCore {
    var rawValue: aws_input_stream
    let awsStream: AwsStream
    let vtable: AwsInputStreamVtable
    init(awsStream: AwsStream, allocator: Allocator) {
        self.awsStream = awsStream
        rawValue = aws_input_stream()
        self.vtable = AwsInputStreamVtable(allocator: allocator)
        rawValue.vtable = vtable.rawValue
        rawValue.impl = Unmanaged<AwsInputStreamCore>.passUnretained(self).toOpaque()
    }
}

class AwsInputStreamVtable: CStruct {
    private let _rawValue: UnsafeMutablePointer<aws_input_stream_vtable>
    var rawValue: UnsafePointer<aws_input_stream_vtable> { UnsafePointer(_rawValue) }
    let allocator: Allocator
    init(allocator: Allocator) {
        self.allocator = allocator
        _rawValue = allocator.allocate(capacity: 1)
        _rawValue.pointee.seek = doSeek
        _rawValue.pointee.read = doRead
        _rawValue.pointee.get_status = doGetStatus
        _rawValue.pointee.get_length = doGetLength
        _rawValue.pointee.acquire = {
            _ = Unmanaged<AwsInputStreamCore>.fromOpaque($0!.pointee.impl).retain()
        }
        _rawValue.pointee.release = {
            Unmanaged<AwsInputStreamCore>.fromOpaque($0!.pointee.impl).release()
        }
    }

    typealias RawType = aws_input_stream_vtable
    func withCStruct<Result>(_ body: (aws_input_stream_vtable) -> Result) -> Result {
        return body(_rawValue.pointee)
    }

    deinit {
        allocator.release(_rawValue)
    }
}

private func doSeek(_ stream: UnsafeMutablePointer<aws_input_stream>!,
                    _ offset: Int64,
                    _ seekBasis: aws_stream_seek_basis) -> Int32 {
    let inputStream = Unmanaged<AwsInputStreamCore>.fromOpaque(stream.pointee.impl).takeUnretainedValue()
    if inputStream.awsStream.seek(offset: offset, basis: seekBasis) {
        return AWS_OP_SUCCESS
    }
    return AWS_OP_ERR
}

private func doRead(_ stream: UnsafeMutablePointer<aws_input_stream>!,
                    _ buffer: UnsafeMutablePointer<aws_byte_buf>!) -> Int32 {
    let inputStream = Unmanaged<AwsInputStreamCore>.fromOpaque(stream.pointee.impl).takeUnretainedValue()
    if inputStream.awsStream.read(buffer: &buffer.pointee) {
        return AWS_OP_SUCCESS
    }
    return AWS_OP_ERR
}

private func doGetStatus(_ stream: UnsafeMutablePointer<aws_input_stream>!,
                         _ result: UnsafeMutablePointer<aws_stream_status>!) -> Int32 {
    let inputStream = Unmanaged<AwsInputStreamCore>.fromOpaque(stream.pointee.impl).takeUnretainedValue()
    //TODO: discuss is it valid to send is valid as always true?
    result.pointee = aws_stream_status(is_end_of_stream: inputStream.awsStream.isEndOfStream, is_valid: true)
    return AWS_OP_SUCCESS
}

private func doGetLength(_ stream: UnsafeMutablePointer<aws_input_stream>!,
                         _ result: UnsafeMutablePointer<Int64>!) -> Int32 {
    let inputStream = Unmanaged<AwsInputStreamCore>.fromOpaque(stream.pointee.impl).takeUnretainedValue()
    let length = inputStream.awsStream.length

    result.pointee = Int64(length)
    return AWS_OP_SUCCESS
}
