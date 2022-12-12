//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCEventStreams
import AwsCIo
import Foundation

public class EventStreamChannelHandler {

    let rawValue: UnsafeMutablePointer<aws_channel_handler>
    let allocator: Allocator
    let onMessageReceivedCallback: (_ errorCode: Int) -> Void
    public init(onMessageReceivedCallback: @escaping (_ errorCode: Int) -> Void,
                initialWindowSize: Int? = nil,
                allocator: Allocator = defaultAllocator) throws {
        self.allocator = allocator
        self.onMessageReceivedCallback = onMessageReceivedCallback

        var options = aws_event_stream_channel_handler_options()
        options.on_message_received = onMessageReceived
        if let initialWindowSize = initialWindowSize {
            options.manual_window_management = true
            options.initial_window_size = initialWindowSize
        }

        guard let rawValue = aws_event_stream_channel_handler_new(allocator.rawValue, &options) else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }

        self.rawValue = rawValue
    }

    public func sendMessage(message: EventStreamMessage) throws {

    }

    // TODO: what to do in deinit? What if this object goes out of scope and onMessageRecieved ie called?
    deinit {
        // allocator.release(rawValue)
    }
}

private func onMessageReceived(
    message: UnsafeMutablePointer<aws_event_stream_message>?,
    errorCode: Int32,
    userData: UnsafeMutableRawPointer!) {

}
