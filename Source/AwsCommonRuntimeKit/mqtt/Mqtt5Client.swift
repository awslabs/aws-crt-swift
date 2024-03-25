///  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
///  SPDX-License-Identifier: Apache-2.0.

import Foundation
import AwsCMqtt
import AwsCIo

private func MqttClientLifeycyleEvents(_ lifecycleEvent: UnsafePointer<aws_mqtt5_client_lifecycle_event>?) {
    print("[Mqtt5 Client Swift] LIFE CYCLE EVENTS")
}

private func MqttClientPublishRecievedEvents(_ publishPacketView: UnsafePointer<aws_mqtt5_packet_publish_view>?, _ userData: UnsafeMutableRawPointer?) {
    print("[Mqtt5 Client Swift] PUBLISH RECIEVED EVENTS")
}

private func MqttClientTerminationCallback(_ userData: UnsafeMutableRawPointer?) {
    // termination callback
    print("[Mqtt5 Client Swift] TERMINATION CALLBACK")
}

public class Mqtt5Client {
     private var rawValue: UnsafeMutablePointer<aws_mqtt5_client>
     private let clientOptions: MqttClientOptions

    init(mqtt5ClientOptions options: MqttClientOptions) throws {
        self.clientOptions = options
        var raw_options = aws_mqtt5_client_options()
        var rawValue: UnsafeMutablePointer<aws_mqtt5_client>?

        let getRawValue: () -> UnsafeMutablePointer<aws_mqtt5_client>? = {
            UnsafeMutablePointer(aws_mqtt5_client_new(allocator.rawValue, &raw_options))
        }

        options.hostName.withByteCursor { hostNameByteCursor in
            raw_options.host_name = hostNameByteCursor
        }
        raw_options.port = options.port

        raw_options.bootstrap = options.bootstrap.rawValue
        raw_options.socket_options = options.socketOptions.withCPointer({ socketOptionPointer in return socketOptionPointer})

        var tls_options: TLSConnectionOptions = TLSConnectionOptions(context: options.tlsCtx)
        raw_options.tls_options = tls_options.withCPointer { cTlsOptions in
            return cTlsOptions
        }

        // TODO: CALLBACKS, callback related changes will be brought in next PR. This is a temp callback
        raw_options.lifecycle_event_handler = MqttClientLifeycyleEvents
        raw_options.publish_received_handler = MqttClientPublishRecievedEvents

        if let _httpProxyOptions = options.httpProxyOptions {
            raw_options.http_proxy_options = _httpProxyOptions.withCPointer({ options in
                return options
            })
        }

        if let _sessionBehavior = options.sessionBehavior {
            let cValue = aws_mqtt5_client_session_behavior_type(UInt32(_sessionBehavior.rawValue))
            raw_options.session_behavior = cValue
        }

        if let _extendedValidationAndFlowControlOptions = options.extendedValidationAndFlowControlOptions {
            let cValue = aws_mqtt5_extended_validation_and_flow_control_options(UInt32(_extendedValidationAndFlowControlOptions.rawValue))
            raw_options.extended_validation_and_flow_control_options = cValue
        }

        if let _offlineQueueBehavior = options.offlineQueueBehavior {
            let cValue = aws_mqtt5_client_operation_queue_behavior_type(UInt32(_offlineQueueBehavior.rawValue))
            raw_options.offline_queue_behavior = cValue
        }

        if let _jitterMode = options.retryJitterMode {
            raw_options.retry_jitter_mode = _jitterMode.rawValue
        }

        if let _minReconnectDelayMs = options.minReconnectDelayMs {
            raw_options.min_reconnect_delay_ms = _minReconnectDelayMs
        }

        if let _maxReconnectDelayMs = options.minReconnectDelayMs {
            raw_options.max_reconnect_delay_ms = _maxReconnectDelayMs
        }

        if let _minConnectedTimeToResetReconnectDelayMs = options.minConnectedTimeToResetReconnectDelayMs {
            raw_options.min_connected_time_to_reset_reconnect_delay_ms = _minConnectedTimeToResetReconnectDelayMs
        }

        if let _pingTimeoutMs = options.pingTimeoutMs {
            raw_options.ping_timeout_ms = _pingTimeoutMs
        }

        if let _connackTimeoutMs = options.connackTimeoutMs {
            raw_options.connack_timeout_ms = _connackTimeoutMs
        }

        if let _ackTimeoutSec = options.ackTimeoutSec {
            raw_options.ack_timeout_seconds = _ackTimeoutSec
        }

        if let _topicAliasingOptions = options.topicAliasingOptions {
            raw_options.topic_aliasing_options = _topicAliasingOptions.withCPointer { pointer in return pointer }
        }

        // We assign a default connection option if options is not set
        var _connnectOptions = options.connectOptions
        if _connnectOptions == nil {
            _connnectOptions =  MqttConnectOptions()
        }

        _connnectOptions!.withCPointer { optionsPointer in
            raw_options.connect_options = optionsPointer
            rawValue = getRawValue()
        }

        if rawValue != nil {
            self.rawValue = rawValue!
        } else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }

    }

    deinit {
        aws_mqtt5_client_release(rawValue)
    }

    /// TODO: Discard all client operations and force releasing the client. The client could not perform any operation after calling this function.
    public func close() {
        // TODO
    }
}
