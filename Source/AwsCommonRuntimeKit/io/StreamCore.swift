//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo


/// aws_input_stream has acquire and release functions which manage the lifetime of this object.
class AwsInputStreamCore {
    var rawValue: aws_input_stream
    let awsStream: AwsStream

    private let allocator: Allocator
    private var vtable = aws_input_stream_vtable(seek: doSeek,
            read: doRead,
            get_status: doGetStatus,
            get_length: doGetLength,
            acquire: { _ = Unmanaged<AwsInputStream>.fromOpaque($0!.pointee.impl).retain() },
            release: { Unmanaged<AwsInputStream>.fromOpaque($0!.pointee.impl).release() })
    private let vtablePointer: UnsafeMutablePointer<aws_input_stream_vtable>

    init(awsStream: AwsStream, allocator: Allocator) {
        self.allocator = allocator
        self.awsStream = awsStream
        rawValue = aws_input_stream()

        // Use a manually managed vtable pointer to avoid undefined behavior
        self.vtablePointer = allocator.allocate(capacity: 1).initialize(to: vtable)
        rawValue.vtable = UnsafePointer(vtablePointer)

        rawValue.impl = Unmanaged<AwsInputStreamCore>.passUnretained(self).toOpaque()
    }

    deinit {
        allocator.release(vtablePointer)
    }
}

private func doSeek(_ stream: UnsafeMutablePointer<aws_input_stream>!,
                    _ offset: Int64,
                    _ seekBasis: aws_stream_seek_basis) -> Int32 {
    let inputStream = Unmanaged<AwsInputStreamCore>.fromOpaque(stream.pointee.impl).takeUnretainedValue()
    if inputStream.awsStream.seek(offset: offset, streamSeekType: StreamSeekType(rawValue: seekBasis.rawValue)!) {
        return AWS_OP_SUCCESS
    }
    return AWS_OP_ERR
}

private func doRead(_ stream: UnsafeMutablePointer<aws_input_stream>!,
                    _ buffer: UnsafeMutablePointer<aws_byte_buf>!) -> Int32 {
    let awsStream = Unmanaged<AwsInputStreamCore>.fromOpaque(stream.pointee.impl).takeUnretainedValue().awsStream
    let length = buffer.pointee.capacity
    let data = awsStream.read(length: length)

    // Invalid data length
    if data.count > length || (data.count == 0 && !awsStream.isEndOfStream) {
        return aws_raise_error(Int32(AWS_IO_STREAM_READ_FAILED.rawValue))
    }

    // We get a "safe" buffer from C that starts where the existing data ends.
    // So we can't accidentally override it.
    if data.count > 0 {
        data.copyBytes(to: buffer.pointee.buffer, count: data.count)
        buffer.pointee.len = data.count
    }

    return AWS_OP_SUCCESS
}

private func doGetStatus(_ stream: UnsafeMutablePointer<aws_input_stream>!,
                         _ result: UnsafeMutablePointer<aws_stream_status>!) -> Int32 {
    let inputStream = Unmanaged<AwsInputStreamCore>.fromOpaque(stream.pointee.impl).takeUnretainedValue()
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
