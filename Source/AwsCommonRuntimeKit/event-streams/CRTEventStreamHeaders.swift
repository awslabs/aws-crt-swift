//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCEventStreams
import struct Foundation.UUID

public struct CRTEventStreamHeaders {
    let rawValue: UnsafeMutablePointer<aws_array_list>
    let headers: [CRTEventStreamHeader]
    
    func addHeader(header: CRTEventStreamHeader) {
        switch header.type {
        case .boolTrue, .boolFalse:
            if let bool = Bool(string: header.value) {
                aws_event_stream_add_bool_header(rawValue, header.name, UInt8(header.name.count), bool.int8Value)
            }
        case .byte:
            if let int8Value = Int8(header.value) {
                aws_event_stream_add_byte_header(rawValue, header.name, UInt8(header.name.count), int8Value)
            }
        case .int16:
            if let int16Value = Int16(header.value) {
                aws_event_stream_add_int16_header(rawValue, header.name, UInt8(header.name.count), int16Value)
            }
        case .int32:
            if let int32Value = Int32(header.value) {
                aws_event_stream_add_int32_header(rawValue, header.name, UInt8(header.name.count), int32Value)
            }
        case .int64:
            if let int64Value = Int64(header.value) {
                aws_event_stream_add_int64_header(rawValue, header.name, UInt8(header.name.count), int64Value)
            }
        case .byteBuf:
            let pointer: UnsafeMutablePointer<UInt8> = allocatePointer()
            if let value = header.value.data(using: .utf8) {
                let range: Range = 0..<value.count
                value.copyBytes(to: pointer, from: range)
                aws_event_stream_add_bytebuf_header(rawValue, header.name, UInt8(header.name.count), pointer, UInt16(value.count), Int8(value.count))
            }
            
        case .string:
            aws_event_stream_add_string_header(rawValue, header.name, UInt8(header.name.count), header.value.asCStr(), UInt16(header.value.count), Int8(header.value.count))
        case .timestamp:
            if let timeStampValue = Int64(header.value) {
                aws_event_stream_add_timestamp_header(rawValue, header.name, UInt8(header.name.count), timeStampValue)
            }
        case .uuid:
            if let uuid = UUID(uuidString: header.value)?.uuid {
                let pointer: UnsafeMutablePointer<UInt8> = fromPointer(ptr: uuid.0)
                aws_event_stream_add_uuid_header(rawValue, header.name, UInt8(header.name.count), pointer)
            }
        }
    }
}
