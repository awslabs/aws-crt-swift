//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCMqtt

public typealias OnConnectionInterrupted =  (UnsafeMutablePointer<aws_mqtt_client_connection>?, Int32) -> Void
public typealias OnConnectionResumed = (UnsafeMutablePointer<aws_mqtt_client_connection>?, MqttReturnCode, Bool) -> Void
public typealias OnDisconnect = (UnsafeMutablePointer<aws_mqtt_client_connection>?) -> Void
public typealias OnConnectionComplete = (UnsafeMutablePointer<aws_mqtt_client_connection>?, Int32, MqttReturnCode, Bool) -> Void
public typealias OnWebSocketHandshakeIntercept = (HttpRequest, OnWebSocketHandshakeInterceptComplete?) -> Void
public typealias OnWebSocketHandshakeInterceptComplete = (HttpRequest, Int32) -> Void

struct MqttConnectionCallbackData {
    var onConnectionInterrupted: OnConnectionInterrupted
    var onConnectionResumed: OnConnectionResumed
    var onDisconnect: OnDisconnect
    var onConnectionComplete:OnConnectionComplete
    var onWebSocketHandshakeIntercept: OnWebSocketHandshakeIntercept?
    var onWebSocketHandshakeInterceptComplete: OnWebSocketHandshakeInterceptComplete?

    init(onConnectionInterrupted: @escaping OnConnectionInterrupted,
         onConnectionResumed: @escaping OnConnectionResumed,
         onDisconnect: @escaping OnDisconnect,
         onConnectionComplete: @escaping OnConnectionComplete,
         onWebSocketHandshakeIntercept: OnWebSocketHandshakeIntercept? = nil,
         onWebSocketHandshakeInterceptComplete: OnWebSocketHandshakeInterceptComplete? = nil) {
        self.onConnectionInterrupted = onConnectionInterrupted
        self.onConnectionResumed = onConnectionResumed
        self.onDisconnect = onDisconnect
        self.onConnectionComplete = onConnectionComplete
        self.onWebSocketHandshakeIntercept = onWebSocketHandshakeIntercept
        self.onWebSocketHandshakeInterceptComplete = onWebSocketHandshakeInterceptComplete
    }
}
