//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import Foundation

public typealias OnPublishReceived = (MqttConnection, String, Data) -> Void

struct PubCallbackData {
    let onPublishReceived: OnPublishReceived
    unowned var mqttConnection: MqttConnection
    
    init(onPublishReceived: @escaping OnPublishReceived,
         mqttConnection: MqttConnection) {
        self.onPublishReceived = onPublishReceived
        self.mqttConnection = mqttConnection
    }
}
