//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCEventStreams

public struct CRTEventStreamHeader {
        public var rawValue: aws_event_stream_header_value_pair
        public var name: String {
            return String(tupleOfCChars: rawValue.header_name)

        }
        public var value: String {
            return String(tupleOfCChars: rawValue.header_value.static_val)

        }
        public var type: EventStreamHeaderType {
            return EventStreamHeaderType(rawValue: rawValue.header_value_type)
        }

        init(name: String,
             value: String,
             type: EventStreamHeaderType = .boolTrue) {
            let emptyTuple: (Int8, Int8, Int8) = (0, 0, 0)
            var headerValuePair = aws_event_stream_header_value_pair(header_name_len: UInt8(name.count), header_name: emptyTuple, header_value_type: type.rawValue, header_value: nil, header_value_len: UInt16(value.count), value_owned: 1)
            name.copyTo(tuple: &headerValuePair.header_name)
            value.copyTo(tuple: &headerValuePair.header_value)
        }
    
}
