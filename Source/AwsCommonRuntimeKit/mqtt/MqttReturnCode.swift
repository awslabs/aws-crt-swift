//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCMqtt

public enum MqttReturnCode {
    case accepted
    case unaceptableProtocolVersion
    case identifierRejected
    case serverUnavailable
    case badUsernameOrPassword
    case notAuthorized
}

extension MqttReturnCode: RawRepresentable, CaseIterable {
    public init(rawValue: aws_mqtt_connect_return_code) {
        let value = Self.allCases.first(where: { $0.rawValue == rawValue })
        self = value ?? .accepted
    }

    public var rawValue: aws_mqtt_connect_return_code {
        switch self {
        case .accepted: return AWS_MQTT_CONNECT_ACCEPTED
        case .unaceptableProtocolVersion: return AWS_MQTT_CONNECT_UNACCEPTABLE_PROTOCOL_VERSION
        case .identifierRejected: return AWS_MQTT_CONNECT_IDENTIFIER_REJECTED
        case .serverUnavailable: return AWS_MQTT_CONNECT_SERVER_UNAVAILABLE
        case .badUsernameOrPassword: return AWS_MQTT_CONNECT_BAD_USERNAME_OR_PASSWORD
        case .notAuthorized: return AWS_MQTT_CONNECT_NOT_AUTHORIZED
        }
    }
}
