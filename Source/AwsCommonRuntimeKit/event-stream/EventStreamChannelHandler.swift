////  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
////  SPDX-License-Identifier: Apache-2.0.
//
//import AwsCEventStreams
//import AwsCIo
//import Foundation
//
////TODO: should we only trigger callback if it was success? Feels a bit redundant with throws,
//// or remove the callback at all
//public typealias OnMessageWritten = (EventStreamMessage?, CommonRunTimeError?) -> Void
//public typealias OnMessageReceived = (Result<EventStreamMessage, Error>) -> Void
//
//class OnMessageReceivedClass {
//    let onMessageReceivedCallback: OnMessageReceived
//    init(_ onMessageReceivedCallback: @escaping OnMessageReceived) {
//        self.onMessageReceivedCallback = onMessageReceivedCallback
//    }
//}
//
//public class EventStreamChannelHandler {
//
//    let rawValue: UnsafeMutablePointer<aws_channel_handler>
//    let allocator: Allocator
//    let onMessageReceivedClass: OnMessageReceivedClass
//    public init(onMessageReceivedCallback: @escaping OnMessageReceived,
//                connection: HTTPClientConnection,
//                initialWindowSize: Int? = nil,
//                allocator: Allocator = defaultAllocator) throws {
//        self.allocator = allocator
//        self.onMessageReceivedClass = OnMessageReceivedClass(onMessageReceivedCallback)
//
//        var options = aws_event_stream_channel_handler_options()
//        options.on_message_received = onMessageReceived
//        options.user_data = Unmanaged<OnMessageReceivedClass>.passUnretained(onMessageReceivedClass).toOpaque()
//        if let initialWindowSize = initialWindowSize {
//            options.manual_window_management = true
//            options.initial_window_size = initialWindowSize
//        }
//
//        guard let rawValue = aws_event_stream_channel_handler_new(allocator.rawValue, &options) else {
//            throw CommonRunTimeError.crtError(.makeFromLastError())
//        }
//
//        self.rawValue = rawValue
//    }
//
//    //TODO: documentation, do we even need the callback?
//    public func sendMessage(message: EventStreamMessage, onMessageWritten: OnMessageWritten?) async throws {
//        return try await withCheckedThrowingContinuation ({ (continuation: CheckedContinuation<(), Error>) in
//            let core = EventStreamChannelHandlerCore(
//                    continuation: continuation,
//                    handler: self,
//                    messageWrittenCallback: onMessageWritten)
//            guard aws_event_stream_channel_handler_write_message(
//                    rawValue,
//                    &message.rawValue,
//                    onMessageWrittenCallback,
//                    core.passRetained()) == AWS_OP_SUCCESS else {
//                core.release()
//                continuation.resume(throwing: CommonRunTimeError.crtError(.makeFromLastError()))
//                return
//            }
//        })
//    }
//
//    // TODO: what to do in deinit? What if this object goes out of scope and onMessageReceived ie called?
//    deinit {
//     //   allocator.release(rawValue)
//    }
//}
//
//class EventStreamChannelHandlerCore {
//    let continuation: CheckedContinuation<(), Error>
//    let handler: EventStreamChannelHandler
//    let messageWrittenCallback: OnMessageWritten?
//
//    init(continuation: CheckedContinuation<(), Error>,
//         handler: EventStreamChannelHandler,
//         messageWrittenCallback: OnMessageWritten?) {
//        self.continuation = continuation
//        self.handler = handler
//        self.messageWrittenCallback = messageWrittenCallback
//    }
//
//    func passRetained() -> UnsafeMutableRawPointer {
//        Unmanaged.passRetained(self).toOpaque()
//    }
//
//    func release() {
//        Unmanaged.passUnretained(self).release()
//    }
//}
//
//private func onMessageWrittenCallback(
//        message: UnsafeMutablePointer<aws_event_stream_message>?,
//        errorCode: Int32,
//        userData: UnsafeMutableRawPointer!) {
//    let core = Unmanaged<EventStreamChannelHandlerCore>.fromOpaque(userData).takeRetainedValue()
//    guard errorCode == AWS_OP_SUCCESS else {
//        let error = CommonRunTimeError.crtError(CRTError(code: errorCode))
//        core.messageWrittenCallback?(nil, error)
//        core.continuation.resume(throwing: error)
//        return
//    }
//
//    let eventStreamMessage = EventStreamMessage(rawValue: message!.pointee)
//
//    // SUCCESS
//    core.messageWrittenCallback?(eventStreamMessage, nil)
//    core.continuation.resume()
//}
//
//private func onMessageReceived(
//    message: UnsafeMutablePointer<aws_event_stream_message>?,
//    errorCode: Int32,
//    userData: UnsafeMutableRawPointer!) {
//
//    let callback = Unmanaged<OnMessageReceivedClass>.fromOpaque(userData).takeUnretainedValue().onMessageReceivedCallback
//    guard errorCode == AWS_OP_SUCCESS else {
//        callback(.failure(CommonRunTimeError.crtError(CRTError(code: errorCode))))
//        return
//    }
//
//    // SUCCESS
//    callback(.success(EventStreamMessage(rawValue: message!.pointee)))
//}
