//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo
import AwsCCommon

/// aws_input_stream has acquire and release functions which manage the lifetime of this object.
class IStreamCore {
    var rawValue: aws_input_stream
    let iStreamable: IStreamable
    var isEndOfStream: Bool = false
    private let allocator: Allocator
    private var vtable = aws_input_stream_vtable(seek: doSeek,
            read: doRead,
            get_status: doGetStatus,
            get_length: doGetLength,
            acquire: { _ = Unmanaged<IStreamCore>.fromOpaque($0!.pointee.impl).retain() },
            release: { Unmanaged<IStreamCore>.fromOpaque($0!.pointee.impl).release() })
    private let vtablePointer: UnsafeMutablePointer<aws_input_stream_vtable>

    init(iStreamable: IStreamable, allocator: Allocator) {
        self.allocator = allocator
        self.iStreamable = iStreamable
        rawValue = aws_input_stream()
        // Use a manually managed vtable pointer to avoid undefined behavior
        self.vtablePointer = allocator.allocate(capacity: 1)
        vtablePointer.initialize(to: vtable)
        rawValue.vtable = UnsafePointer(vtablePointer)

        rawValue.impl = Unmanaged<IStreamCore>.passUnretained(self).toOpaque()
    }

    deinit {
        allocator.release(vtablePointer)
    }
}

private func doSeek(_ stream: UnsafeMutablePointer<aws_input_stream>!,
                    _ offset: Int64,
                    _ seekBasis: aws_stream_seek_basis) -> Int32 {
    let iStreamCore = Unmanaged<IStreamCore>.fromOpaque(stream.pointee.impl).takeUnretainedValue()
    let iStreamable = iStreamCore.iStreamable
    //TODO: Handle Invalid Offset
    do {
        let streamSeekType = StreamSeekType(rawValue: seekBasis.rawValue)!
        let targetOffset: UInt64
        switch streamSeekType {
        case .begin: targetOffset = UInt64(offset)
        case .end: targetOffset = try iStreamable.length() - UInt64(abs(offset))
        }

        try iStreamable.seek(offset: targetOffset)
        iStreamCore.isEndOfStream = false
        return AWS_OP_SUCCESS
    } catch {
        //TODO: fix error
        return aws_raise_error(Int32(AWS_IO_STREAM_INVALID_SEEK_POSITION.rawValue))
    }
}

//TODO: Fix read
private func doRead(_ stream: UnsafeMutablePointer<aws_input_stream>!,
                    _ buffer: UnsafeMutablePointer<aws_byte_buf>!) -> Int32 {
    let iStreamCore = Unmanaged<IStreamCore>.fromOpaque(stream.pointee.impl).takeUnretainedValue()
    let iStreamable = iStreamCore.iStreamable
    do {
        let length = try iStreamable.read(buffer: buffer.pointee.buffer, maxLength: buffer.pointee.capacity)
        // Invalid data length
        if length > buffer.pointee.capacity {
            return aws_raise_error(Int32(AWS_IO_STREAM_READ_FAILED.rawValue))
        }
        buffer.pointee.len = length
        if length == 0 {
            iStreamCore.isEndOfStream = true
        }

        return AWS_OP_SUCCESS
    } catch {
        //TODO: throw proper error
        return AWS_OP_ERR
    }

}

private func doGetStatus(_ stream: UnsafeMutablePointer<aws_input_stream>!,
                         _ result: UnsafeMutablePointer<aws_stream_status>!) -> Int32 {
    let iStreamable = Unmanaged<IStreamCore>.fromOpaque(stream.pointee.impl).takeUnretainedValue().iStreamable
    do {
        let isEndOfStream = try iStreamable.isEndOfStream()
        result.pointee = aws_stream_status(is_end_of_stream: isEndOfStream, is_valid: true)
        return AWS_OP_SUCCESS
    } catch {
        //TODO: throw proper error
        return AWS_OP_ERR
    }
}

private func doGetLength(_ stream: UnsafeMutablePointer<aws_input_stream>!,
                         _ result: UnsafeMutablePointer<Int64>!) -> Int32 {
    let inputStream = Unmanaged<IStreamCore>.fromOpaque(stream.pointee.impl).takeUnretainedValue()
    do {
        let length = try inputStream.iStreamable.length()
        result.pointee = Int64(length)
        return AWS_OP_SUCCESS
    } catch {
        //TODO: throw proper error
        return AWS_OP_ERR
    }
}
