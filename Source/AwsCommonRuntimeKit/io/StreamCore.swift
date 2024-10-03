//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo
import AwsCCommon

/// aws_input_stream has acquire and release functions which manage the lifetime of this object.
class IStreamCore {
    var rawValue: UnsafeMutablePointer<aws_input_stream>
    let iStreamable: IStreamable
    var isEndOfStream: Bool = false
    private var vtable = aws_input_stream_vtable(
        seek: doSeek,
        read: doRead,
        get_status: doGetStatus,
        get_length: doGetLength,
        acquire: { _ = Unmanaged<IStreamCore>.fromOpaque($0!.pointee.impl).retain() },
        release: { Unmanaged<IStreamCore>.fromOpaque($0!.pointee.impl).release() }
    )
    private let vtablePointer: UnsafeMutablePointer<aws_input_stream_vtable>

    init(iStreamable: IStreamable) {
        self.iStreamable = iStreamable
        rawValue = allocator.allocate(capacity: 1)
        // Use a manually managed vtable pointer to avoid undefined behavior
        self.vtablePointer = allocator.allocate(capacity: 1)
        vtablePointer.initialize(to: vtable)
        rawValue.pointee.vtable = UnsafePointer(vtablePointer)

        rawValue.pointee.impl = Unmanaged<IStreamCore>.passUnretained(self).toOpaque()
    }

    deinit {
        allocator.release(rawValue)
        allocator.release(vtablePointer)
    }
}

private func doSeek(_ stream: UnsafeMutablePointer<aws_input_stream>!,
                    _ offset: Int64,
                    _ seekBasis: aws_stream_seek_basis) -> Int32 {
    let iStreamCore = Unmanaged<IStreamCore>.fromOpaque(stream.pointee.impl).takeUnretainedValue()
    let iStreamable = iStreamCore.iStreamable
    do {
        let streamSeekType = StreamSeekType(rawValue: UInt32(seekBasis.rawValue))!
        try iStreamable.seek(offset: offset, streamSeekType: streamSeekType)
        iStreamCore.isEndOfStream = false
        return AWS_OP_SUCCESS
    } catch CommonRunTimeError.crtError(let crtError) {
        return aws_raise_error(crtError.code)
    } catch {
        return aws_raise_error(Int32(AWS_IO_STREAM_SEEK_FAILED.rawValue))
    }
}

private func doRead(_ stream: UnsafeMutablePointer<aws_input_stream>!,
                    _ buffer: UnsafeMutablePointer<aws_byte_buf>!) -> Int32 {
    let iStreamCore = Unmanaged<IStreamCore>.fromOpaque(stream.pointee.impl).takeUnretainedValue()
    let iStreamable = iStreamCore.iStreamable
    do {
        let bufferPointer = UnsafeMutableBufferPointer.init(
            start: buffer.pointee.buffer,
            count: buffer.pointee.capacity)
        let bytesRead = try iStreamable.read(buffer: bufferPointer)
        if let bytesRead = bytesRead {
            buffer.pointee.len = bytesRead
        } else {
            iStreamCore.isEndOfStream = true
        }

        return AWS_OP_SUCCESS
    } catch CommonRunTimeError.crtError(let crtError) {
        return aws_raise_error(crtError.code)
    } catch {
        return aws_raise_error(Int32(AWS_IO_STREAM_READ_FAILED.rawValue))
    }
}

private func doGetStatus(_ stream: UnsafeMutablePointer<aws_input_stream>!,
                         _ result: UnsafeMutablePointer<aws_stream_status>!) -> Int32 {
    let iStreamCore = Unmanaged<IStreamCore>.fromOpaque(stream.pointee.impl).takeUnretainedValue()
    result.pointee = aws_stream_status(is_end_of_stream: iStreamCore.isEndOfStream, is_valid: true)
    return AWS_OP_SUCCESS
}

private func doGetLength(_ stream: UnsafeMutablePointer<aws_input_stream>!,
                         _ result: UnsafeMutablePointer<Int64>!) -> Int32 {
    let inputStream = Unmanaged<IStreamCore>.fromOpaque(stream.pointee.impl).takeUnretainedValue()
    do {
        let length = try inputStream.iStreamable.length()
        result.pointee = Int64(length)
        return AWS_OP_SUCCESS
    } catch CommonRunTimeError.crtError(let crtError) {
        return aws_raise_error(crtError.code)
    } catch {
        return aws_raise_error(Int32(AWS_IO_STREAM_GET_LENGTH_FAILED.rawValue))
    }
}
