//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCEventStream
import AwsCCommon
import Foundation

public typealias OnPayloadSegment = (_ payload: Data, _ finalSegment: Bool) -> Void
public typealias OnPreludeReceived = (_ totalLength: UInt32, _ headersLength: UInt32) -> Void
public typealias OnHeaderReceived = (EventStreamHeader) -> Void
public typealias OnComplete = () -> Void
public typealias OnError = (_ code: Int32, _ message: String) -> Void

public class EventStreamMessageDecoder {
    var rawValue: aws_event_stream_streaming_decoder
    let callbackCore: EventStreamMessageDecoderCallbackCore

    /// Initialize a streaming decoder for messages with callbacks for usage
    /// - Parameters:
    ///   - onPayloadSegment: Called when payload data has been received.
    ///                       FinalSegment indicates if the current data is the last payload buffer for that message.
    ///   - onPreludeReceived: Called when a new message has arrived. The prelude will contain metadata about the message.
    ///                        At this point no headers or payload have been received.
    ///   - onHeaderReceived: Called when a header is encountered.
    ///   - onComplete: Called when a message decoding is complete and CRC is verified.
    ///   - onError: Called when an error is encountered. The decoder is not in a good state for usage after this callback.
    ///   - allocator: (Optional) allocator to override.
    public init(onPayloadSegment: @escaping OnPayloadSegment,
                onPreludeReceived: @escaping OnPreludeReceived,
                onHeaderReceived: @escaping OnHeaderReceived,
                onComplete: @escaping OnComplete,
                onError: @escaping OnError,
                allocator: Allocator = defaultAllocator) {

        rawValue = aws_event_stream_streaming_decoder()
        callbackCore = EventStreamMessageDecoderCallbackCore(
            onPayloadSegment: onPayloadSegment,
            onPreludeReceived: onPreludeReceived,
            onHeaderReceived: onHeaderReceived,
            onComplete: onComplete,
            onError: onError)

        var decoderOptions = aws_event_stream_streaming_decoder_options()
        decoderOptions.on_payload_segment = onPayloadSegmentFn
        decoderOptions.on_prelude = onPreludeReceivedFn
        decoderOptions.on_header = onHeaderReceivedFn
        decoderOptions.on_complete = onCompleteFn
        decoderOptions.on_error = onErrorFn
        decoderOptions.user_data = callbackCore.passUnretained()

        aws_event_stream_streaming_decoder_init_from_options(&rawValue, allocator.rawValue, &decoderOptions)
    }

    /// Pass data to decode. This will trigger the callbacks with the decoded result.
    /// - Parameter data:  The data to decode
    /// - Throws: CommonRunTimeError.crtException
    public func decode(data: Data) throws {
        guard data.withAWSByteBufPointer({
            aws_event_stream_streaming_decoder_pump(
                &rawValue,
                $0)
        }) == AWS_OP_SUCCESS
        else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
    }

    deinit {
        aws_event_stream_streaming_decoder_clean_up(&rawValue)
    }
}

/// Wrapper for callbacks to use with Unmanaged
class EventStreamMessageDecoderCallbackCore {
    let onPayloadSegment: OnPayloadSegment
    let onPreludeReceived: OnPreludeReceived
    let onHeaderReceived: OnHeaderReceived
    let onComplete: OnComplete
    let onError: OnError

    init(onPayloadSegment: @escaping OnPayloadSegment,
         onPreludeReceived: @escaping OnPreludeReceived,
         onHeaderReceived: @escaping OnHeaderReceived,
         onComplete: @escaping OnComplete,
         onError: @escaping OnError) {
        self.onPayloadSegment = onPayloadSegment
        self.onPreludeReceived = onPreludeReceived
        self.onHeaderReceived = onHeaderReceived
        self.onComplete = onComplete
        self.onError = onError
    }

    func passUnretained() -> UnsafeMutableRawPointer {
        Unmanaged.passUnretained(self).toOpaque()
    }
}

private func onPayloadSegmentFn(
    decoder: UnsafeMutablePointer<aws_event_stream_streaming_decoder>?,
    payload: UnsafeMutablePointer<aws_byte_buf>!,
    finalSegment: Int8,
    userData: UnsafeMutableRawPointer!) {
    let callbackCore = Unmanaged<EventStreamMessageDecoderCallbackCore>
        .fromOpaque(userData)
        .takeUnretainedValue()

    let data = Data(bytes: payload.pointee.buffer, count: payload.pointee.len)
    callbackCore.onPayloadSegment(data, finalSegment != 0)
}

private func onPreludeReceivedFn(
    decoder: UnsafeMutablePointer<aws_event_stream_streaming_decoder>?,
    prelude: UnsafeMutablePointer<aws_event_stream_message_prelude>!,
    userData: UnsafeMutableRawPointer!) {
    let callbackCore = Unmanaged<EventStreamMessageDecoderCallbackCore>
        .fromOpaque(userData)
        .takeUnretainedValue()

    callbackCore.onPreludeReceived(
        prelude.pointee.total_len,
        prelude.pointee.headers_len)
}

private func onHeaderReceivedFn(
    decoder: UnsafeMutablePointer<aws_event_stream_streaming_decoder>?,
    prelude: UnsafeMutablePointer<aws_event_stream_message_prelude>?,
    header: UnsafeMutablePointer<aws_event_stream_header_value_pair>!,
    userData: UnsafeMutableRawPointer!) {
    let callbackCore = Unmanaged<EventStreamMessageDecoderCallbackCore>
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
    let value = EventStreamHeaderValue.parseRaw(rawValue: header)
    callbackCore.onHeaderReceived(EventStreamHeader(name: name, value: value))
}

private func onCompleteFn(
    decoder: UnsafeMutablePointer<aws_event_stream_streaming_decoder>?,
    messageCrc: UInt32,
    userData: UnsafeMutableRawPointer!) {
    let callbackCore = Unmanaged<EventStreamMessageDecoderCallbackCore>
        .fromOpaque(userData)
        .takeUnretainedValue()
    callbackCore.onComplete()
}

private func onErrorFn(
    decoder: UnsafeMutablePointer<aws_event_stream_streaming_decoder>?,
    prelude: UnsafeMutablePointer<aws_event_stream_message_prelude>?,
    errorCode: Int32,
    message: UnsafePointer<CChar>!,
    userData: UnsafeMutableRawPointer!) {
    let callbackCore = Unmanaged<EventStreamMessageDecoderCallbackCore>
        .fromOpaque(userData)
        .takeUnretainedValue()
    callbackCore.onError(errorCode, String(cString: message))
}
