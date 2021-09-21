//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCEventStreams
import AwsCIo

public typealias OnMessageWritten = (CRTEventStreamMessage, AWSError) -> Void
public class CRTEventStreamChannelHandler {
    let rawValue: UnsafeMutablePointer<aws_channel_handler>

    public init(options: CRTEventStreamChannelHandlerOptions, httpConnection: HttpClientConnection, allocator: Allocator = defaultAllocator) {
        let channelHandlerOptions = aws_event_stream_channel_handler_options(on_message_received: { messagePointer, errorCode, userData in
            guard let userData = userData,
                  let messagePointer = messagePointer else {
                return
            }

            let options = userData.assumingMemoryBound(to: CRTEventStreamChannelHandlerOptions.self)
            let message = CRTEventStreamMessage(rawValue: messagePointer)
            let error = AWSError(errorCode: errorCode)
            options.pointee.onMessageReceived(message, error)
            options.deinitializeAndDeallocate()
        }, user_data: fromPointer(ptr: options), initial_window_size: options.initialWindowSize, manual_window_management: options.enableManualWindowManagement)
        let optionsPointer: UnsafePointer<aws_event_stream_channel_handler_options> = fromPointer(ptr: channelHandlerOptions)
        let slot = aws_channel_slot_new(httpConnection.channel)
        aws_channel_slot_insert_end(httpConnection.channel, slot)
        self.rawValue = aws_event_stream_channel_handler_new(allocator.rawValue, optionsPointer)
        aws_channel_slot_set_handler(slot, rawValue)
    }

    public func sendMessage(message: CRTEventStreamMessage, onMessageWritten: @escaping OnMessageWritten) {
        let callbackPointer: UnsafeMutableRawPointer = fromPointer(ptr: onMessageWritten)
        aws_event_stream_channel_handler_write_message(rawValue, message.rawValue, { messagePointer, errorCode, userData in
            guard let userData = userData,
                  let messagePointer = messagePointer else {
                return
            }

            let onMessageWritten = userData.assumingMemoryBound(to: OnMessageWritten.self)
            let message = CRTEventStreamMessage(rawValue: messagePointer)
            let error = AWSError(errorCode: errorCode)
            onMessageWritten.pointee(message, error)
            onMessageWritten.deinitializeAndDeallocate()
        }, callbackPointer)
    }
}
