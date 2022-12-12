//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCEventStreams
import AwsCCommon
import Foundation

public typealias OnPayloadSegment = (_ payload: Data, _ finalSegment: Bool) -> Void
public typealias OnPreludeReceived = (
        _ totalLength: UInt32,
        _ headersLength: UInt32,
        _ crc: UInt32) -> Void
public typealias OnHeaderReceived = (EventStreamHeader) -> Void
public typealias OnError = (_ code: Int32, _ message: String) -> Void

public class EventStreamMessageDecoder {
    var rawValue: aws_event_stream_streaming_decoder
    let allocator: Allocator

    public init(onPayloadSegment: @escaping OnPayloadSegment,
                onPreludeReceived: @escaping OnPreludeReceived,
                onHeaderReceived: @escaping OnHeaderReceived,
                onError: @escaping OnError,
                allocator: Allocator = defaultAllocator) {
        self.allocator = allocator
        rawValue = aws_event_stream_streaming_decoder()
        let callbackCore = EventStreamMessageDecoderCallbackCode(
                onPayloadSegment: onPayloadSegment,
                onPreludeReceived: onPreludeReceived,
                onHeaderReceived: onHeaderReceived,
                onError: onError)


        aws_event_stream_streaming_decoder_init(
                &rawValue,
                allocator.rawValue,
                onPayloadSegmentFn,
                onPreludeReceivedFn,
                onHeaderReceivedFn,
                onErrorFn,
                callbackCore.passUnretained()
        )
    }

    func pump(buffer: UnsafeBufferPointer<UInt8>) throws {
        var awsBuffer = aws_byte_buf_from_array(buffer.baseAddress, buffer.count)
        guard aws_event_stream_streaming_decoder_pump(
                &rawValue,
                &awsBuffer) == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
    }

}

class EventStreamMessageDecoderCallbackCode {
    let onPayloadSegment: OnPayloadSegment
    let onPreludeReceived: OnPreludeReceived
    let onHeaderReceived: OnHeaderReceived
    let onError: OnError

    init(onPayloadSegment: @escaping OnPayloadSegment,
         onPreludeReceived: @escaping OnPreludeReceived,
         onHeaderReceived: @escaping OnHeaderReceived,
         onError: @escaping OnError) {
        self.onPayloadSegment = onPayloadSegment
        self.onPreludeReceived = onPreludeReceived
        self.onHeaderReceived = onHeaderReceived
        self.onError = onError
    }

    func passUnretained() -> UnsafeMutableRawPointer {
        return Unmanaged.passUnretained(self).toOpaque()
    }
}

private func onPayloadSegmentFn(
        decoder: UnsafeMutablePointer<aws_event_stream_streaming_decoder>?,
        payload: UnsafeMutablePointer<aws_byte_buf>!,
        finalSegment: Int8,
        userData: UnsafeMutableRawPointer!) {
    let callbackCore = Unmanaged<EventStreamMessageDecoderCallbackCode>
            .fromOpaque(userData)
            .takeUnretainedValue()

    let data = Data(bytes: payload.pointee.buffer, count: payload.pointee.len)
    callbackCore.onPayloadSegment(data, finalSegment == 1)
}

private func onPreludeReceivedFn(
        decoder: UnsafeMutablePointer<aws_event_stream_streaming_decoder>?,
        prelude: UnsafeMutablePointer<aws_event_stream_message_prelude>!,
        userData: UnsafeMutableRawPointer!) {
    let callbackCore = Unmanaged<EventStreamMessageDecoderCallbackCode>
            .fromOpaque(userData)
            .takeUnretainedValue()

    callbackCore.onPreludeReceived(
            prelude.pointee.total_len,
            prelude.pointee.headers_len,
            prelude.pointee.prelude_crc)
}

private func onHeaderReceivedFn(
        decoder: UnsafeMutablePointer<aws_event_stream_streaming_decoder>?,
        prelude: UnsafeMutablePointer<aws_event_stream_message_prelude>?,
        header: UnsafeMutablePointer<aws_event_stream_header_value_pair>!,
        userData: UnsafeMutableRawPointer!) {
    let callbackCore = Unmanaged<EventStreamMessageDecoderCallbackCode>
            .fromOpaque(userData)
            .takeUnretainedValue()

    let name = withUnsafeBytes(
            of: header.pointee.header_name) { (namePointer) -> String in
        let charPtr = namePointer.baseAddress!.assumingMemoryBound(to: CChar.self)
        return String(
            data: Data(
                    bytes: charPtr,
                    count: Int(header.pointee.header_name_len)),
            encoding: .utf8)!
    }
    let value = EventStreamHeaderType.parseRaw(rawValue: header.pointee)
    callbackCore.onHeaderReceived(EventStreamHeader(name: name, value: value))
}

private func onErrorFn(
        decoder: UnsafeMutablePointer<aws_event_stream_streaming_decoder>?,
        prelude: UnsafeMutablePointer<aws_event_stream_message_prelude>?,
        errorCode: Int32,
        message: UnsafePointer<CChar>!,
        userData: UnsafeMutableRawPointer!) {
    let callbackCore = Unmanaged<EventStreamMessageDecoderCallbackCode>
            .fromOpaque(userData)
            .takeUnretainedValue()
    callbackCore.onError(errorCode, String(cString: message))
}
