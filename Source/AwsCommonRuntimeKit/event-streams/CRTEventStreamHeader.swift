//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCEventStreams

public struct CRTEventStreamHeader {
        public var rawValue: aws_event_stream_header_value_pair
        public var name: String {
            var pointer = &rawValue.header_name.0
            return String.fromByteArray(pointer: pointer) ?? ""

        }
        public var value: String {
            return String.fromByteArray(pointer: &rawValue.header_value.static_val) ?? ""

        }
        public var type: EventStreamHeaderType {
            return EventStreamHeaderType(rawValue: rawValue.header_value_type)
        }

        init(name: String,
             value: String,
             type: EventStreamHeaderType = .boolTrue) {
            self.rawValue = aws_event_stream_header_value_pair(header_name_len: name.count, header_name: name.awsByteCursor, header_value_type: type.rawValue, header_value: value.awsByteCursor, header_value_len: value.count, value_owned: true)
        }
    
}
