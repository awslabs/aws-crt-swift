//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCEventStreams

public class CRTEventStreamChannelHandler {
    public init(options: CRTEventStreamChannelHandlerOptions) {
        let channelHandlerOptions = aws_event_stream_channel_handler_options(on_message_received: { messsagePointer, errorCode, userData in
            guard let userData = userData else {
                return
            }
            
            let options = userData.assumingMemoryBound(to: CRTEventStreamChannelHandlerOptions.self)
            
        }, user_data: <#T##UnsafeMutableRawPointer!#>, initial_window_size: <#T##Int#>, manual_window_management: <#T##Bool#>)
    }
}
