//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

public typealias OnSubAck = (MqttConnection, Int16, String, MqttQos, CRTError) -> Void

struct SubAckCallbackData {
    let onSubAck: OnSubAck
    unowned var connection: MqttConnection
    let topic: String?

    init(onSubAck: @escaping OnSubAck,
         connection: MqttConnection,
         topic: String?) {
        self.onSubAck = onSubAck
        self.connection = connection
        self.topic = topic
    }
}
