//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

public typealias OnMultiSubAck = (MqttConnection, Int16, [String], CRTError) -> Void

struct MultiSubAckCallbackData {
    let onMultiSubAck: OnMultiSubAck
    unowned var connection: MqttConnection
    let topics: [String]?

    init(onMultiSubAck: @escaping OnMultiSubAck,
         connection: MqttConnection,
         topics: [String]?)
    {
        self.onMultiSubAck = onMultiSubAck
        self.connection = connection
        self.topics = topics
    }
}
