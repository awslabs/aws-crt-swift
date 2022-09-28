//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AwsCMqtt

public enum MqttQos {
    case atMostOnce
    case atLeastOnce
    case exactlyOnce
    case failure
}

extension MqttQos: RawRepresentable, CaseIterable {
    public init(rawValue: aws_mqtt_qos) {
        let value = Self.allCases.first(where: { $0.rawValue == rawValue })
        self = value ?? .atMostOnce
    }

    public var rawValue: aws_mqtt_qos {
        switch self {
        case .atMostOnce: return AWS_MQTT_QOS_AT_MOST_ONCE
        case .atLeastOnce: return AWS_MQTT_QOS_AT_LEAST_ONCE
        case .exactlyOnce: return AWS_MQTT_QOS_EXACTLY_ONCE
        case .failure: return AWS_MQTT_QOS_FAILURE
        }
    }
}
