//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCEventStreams
import Foundation

public enum EventStreamHeaderType {
    case bool(value: Bool)
    case byte(value: Int8)
    case int16(value: Int16)
    case int32(value: Int32)
    case int64(value: Int64)
    case byteBuf(value: [UInt8]) // TODO: confirm type
    case string(value: String)
    case timestamp(value: TimeInterval)
    case uuid(value: UUID)
}

public struct EventStreamHeader {
    public let name: String
    public let value: EventStreamHeaderType

    public init(name: String, value: EventStreamHeaderType) {
        self.name = name
        self.value = value
    }
}
