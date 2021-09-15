//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCEventStreams

public typealias OnMessageReceived = (CRTEventStreamMessage, AWSError) -> Void
public struct CRTEventStreamChannelHandlerOptions {
    /// initial window size to use for the channel. If automatic window management is set to true, this value is ignored.
    public let initialWindowSize: Int
    /**
      if set to false (the default), windowing will be managed automatically for the user.
      Otherwise, after any on_message_received, the user must invoke
      aws_event_stream_channel_handler_increment_read_window()
     */
    public let enableManualWindowManagement: Bool
    
    public let onMessageReceived: OnMessageReceived
    
    public init(initialWindowSize: Int = Int.max,
                enableManualWindowManagement: Bool = false,
                onMessageReceived: @escaping OnMessageReceived) {
        self.initialWindowSize = initialWindowSize
        self.enableManualWindowManagement = enableManualWindowManagement
        self.onMessageReceived = onMessageReceived
    }
}
