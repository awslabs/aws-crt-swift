//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCEventStreams

public class CRTEventStreamMessage {
    let rawValue: UnsafeMutablePointer<aws_event_stream_message>

    public init(allocator: Allocator = defaultAllocator, headers: CRTEventStreamHeaders, payload: ByteBuffer) {
        self.rawValue = allocatePointer()
        let byteBuf: UnsafeMutablePointer<aws_byte_buf> = fromPointer(ptr: payload.awsByteBuf)
        aws_event_stream_message_init(rawValue, allocator.rawValue, headers.rawValue, byteBuf)
    }
    
    public init(rawValue: UnsafeMutablePointer<aws_event_stream_message>) {
        self.rawValue = rawValue
    }

    deinit {
        aws_event_stream_message_clean_up(rawValue)
    }
}

extension CRTEventStreamMessage: CustomDebugStringConvertible {
    public var debugDescription: String {
        aws_event_stream_message_to_debug_str(stdout, rawValue)
        return "printed event stream message"
    }
}
