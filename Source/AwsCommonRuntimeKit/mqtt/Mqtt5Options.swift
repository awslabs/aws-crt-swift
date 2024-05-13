///  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
///  SPDX-License-Identifier: Apache-2.0.

import Foundation
import AwsCMqtt

/// Configuration for all client topic aliasing behavior.
public class TopicAliasingOptions: CStruct {

    /// Controls what kind of outbound topic aliasing behavior the client should attempt to use.  If topic aliasing is not supported by the server, this setting has no effect and any attempts to directly manipulate the topic alias id in outbound publishes will be ignored.  If left undefined, then outbound topic aliasing is disabled.
    public var outboundBehavior: OutboundTopicAliasBehaviorType?

    /// If outbound topic aliasing is set to LRU, this controls the maximum size of the cache.  If outbound topic aliasing is set to LRU and this is zero or undefined, a sensible default is used (25).  If outbound topic aliasing is not set to LRU, then this setting has no effect.
    public var outboundCacheMaxSize: UInt16?

    /// Controls whether or not the client allows the broker to use topic aliasing when sending publishes.  Even if inbound topic aliasing is enabled, it is up to the server to choose whether or not to use it.  If left undefined, then inbound topic aliasing is disabled.
    public var inboundBehavior: InboundTopicAliasBehaviorType?

    /// If inbound topic aliasing is enabled, this will control the size of the inbound alias cache.  If inbound aliases are enabled and this is zero or undefined, then a sensible default will be used (25).  If inbound aliases are disabled, this setting has no effect.  Behaviorally, this value overrides anything present in the topic_alias_maximum field of the CONNECT packet options.
    public var inboundCacheMaxSize: UInt16?

    typealias RawType = aws_mqtt5_client_topic_alias_options
    func withCStruct<Result>(_ body: (aws_mqtt5_client_topic_alias_options) -> Result) -> Result {
        var raw_topic_alias_options = aws_mqtt5_client_topic_alias_options()
        if let outboundBehavior = outboundBehavior {
            raw_topic_alias_options.outbound_topic_alias_behavior = outboundBehavior.rawValue
        }

        if let outboundCacheMaxSize = outboundCacheMaxSize {
            raw_topic_alias_options.outbound_alias_cache_max_size = outboundCacheMaxSize
        }

        if let inboundBehavior = inboundBehavior {
            raw_topic_alias_options.inbound_topic_alias_behavior = inboundBehavior.rawValue
        }

        if let inboundCacheMaxSize = inboundCacheMaxSize {
            raw_topic_alias_options.inbound_alias_cache_size = inboundCacheMaxSize
        }

        return body(raw_topic_alias_options)
    }

}

/// Data model of an `MQTT5 CONNECT <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901033>`_ packet.
public class MqttConnectOptions: CStruct {
    /// The maximum time interval, in whole seconds, that is permitted to elapse between the point at which the client finishes transmitting one MQTT packet and the point it starts sending the next.  The client will use PINGREQ packets to maintain this property. If the responding CONNACK contains a keep alive property value, then that is the negotiated keep alive value. Otherwise, the keep alive sent by the client is the negotiated value.
    public let keepAliveInterval: TimeInterval?

    /// A unique string identifying the client to the server.  Used to restore session state between connections. If left empty, the broker will auto-assign a unique client id.  When reconnecting, the mqtt5 client will always use the auto-assigned client id.
    public let clientId: String?

    /// A string value that the server may use for client authentication and authorization.
    public let username: String?

    /// Opaque binary data that the server may use for client authentication and authorization.
    public let password: String?

    /// A time interval, in whole seconds, that the client requests the server to persist this connection's MQTT session state for.  Has no meaning if the client has not been configured to rejoin sessions.  Must be non-zero in order to successfully rejoin a session. If the responding CONNACK contains a session expiry property value, then that is the negotiated session expiry value.  Otherwise, the session expiry sent by the client is the negotiated value.
    public let sessionExpiryInterval: TimeInterval?

    /// If true, requests that the server send response information in the subsequent CONNACK.  This response information may be used to set up request-response implementations over MQTT, but doing so is outside the scope of the MQTT5 spec and client.
    public let requestResponseInformation: Bool?

    /// If true, requests that the server send additional diagnostic information (via response string or user properties) in DISCONNECT or CONNACK packets from the server.
    public let requestProblemInformation: Bool?

    /// Notifies the server of the maximum number of in-flight QoS 1 and 2 messages the client is willing to handle.  If omitted or None, then no limit is requested.
    public let receiveMaximum: UInt16?

    /// Notifies the server of the maximum packet size the client is willing to handle.  If omitted or None, then no limit beyond the natural limits of MQTT packet size is requested.
    public let maximumPacketSize: UInt32?

    /// A time interval, in whole seconds, that the server should wait (for a session reconnection) before sending the will message associated with the connection's session.  If omitted or None, the server will send the will when the associated session is destroyed.  If the session is destroyed before a will delay interval has elapsed, then the will must be sent at the time of session declassion.
    public let willDelayInterval: TimeInterval?

    /// The definition of a message to be published when the connection's session is destroyed by the server or when the will delay interval has elapsed, whichever comes first.  If None, then nothing will be sent.
    public let will: PublishPacket?

    /// Array of MQTT5 user properties included with the packet.
    public let userProperties: [UserProperty]?

    public init (keepAliveInterval: TimeInterval? = nil,
                 clientId: String? = nil,
                 username: String? = nil,
                 password: String? = nil,
                 sessionExpiryInterval: TimeInterval? = nil,
                 requestResponseInformation: Bool? = nil,
                 requestProblemInformation: Bool? = nil,
                 receiveMaximum: UInt16? = nil,
                 maximumPacketSize: UInt32? = nil,
                 willDelayInterval: TimeInterval? = nil,
                 will: PublishPacket? = nil,
                 userProperties: [UserProperty]? = nil) {
        self.keepAliveInterval = keepAliveInterval
        self.clientId = clientId
        self.username = username
        self.password = password
        self.sessionExpiryInterval = sessionExpiryInterval
        self.requestResponseInformation = requestResponseInformation
        self.requestProblemInformation = requestProblemInformation
        self.receiveMaximum = receiveMaximum
        self.maximumPacketSize = maximumPacketSize
        self.willDelayInterval = willDelayInterval
        self.will = will
        self.userProperties = userProperties
    }

    func validateConversionToNative() throws {
        if let keepAliveInterval {
            if keepAliveInterval < 0 || keepAliveInterval > Double(UInt16.max) {
                throw MqttError.validation(message: "Invalid keepAliveInterval value")
            }
        }

        do {
            _ = try sessionExpiryInterval?.secondUInt32()
        } catch {
            throw MqttError.validation(message: "Invalid sessionExpiryInterval value")
        }

        do {
            _ = try willDelayInterval?.secondUInt32()
        } catch {
            throw MqttError.validation(message: "Invalid willDelayInterval value")
        }
    }

    typealias RawType = aws_mqtt5_packet_connect_view
    func withCStruct<Result>( _ body: (RawType) -> Result) -> Result {

        var raw_connect_options = aws_mqtt5_packet_connect_view()

        if let keepAlive = self.keepAliveInterval {
            raw_connect_options.keep_alive_interval_seconds = UInt16(keepAlive)
        }

        let _sessionExpiryIntervalSec: UInt32?  = try? self.sessionExpiryInterval?.secondUInt32()
        let _requestResponseInformation: UInt8? = self.requestResponseInformation?.uint8Value
        let _requestProblemInformation: UInt8? = self.requestProblemInformation?.uint8Value
        let _willDelayIntervalSec: UInt32? = try? self.willDelayInterval?.secondUInt32()

        return withOptionalUnsafePointers(
            _sessionExpiryIntervalSec,
            _requestResponseInformation,
            _requestProblemInformation,
            _willDelayIntervalSec,
            self.receiveMaximum,
            self.maximumPacketSize) { sessionExpiryIntervalSecPointer,
                                      requestResponseInformationPointer,
                                      requestProblemInformationPointer,
                                      willDelayIntervalSecPointer,
                                      receiveMaximumPointer,
                                      maximumPacketSizePointer in

                raw_connect_options.session_expiry_interval_seconds = sessionExpiryIntervalSecPointer
                raw_connect_options.request_response_information = requestResponseInformationPointer
                raw_connect_options.request_problem_information = requestProblemInformationPointer
                raw_connect_options.will_delay_interval_seconds = willDelayIntervalSecPointer
                raw_connect_options.receive_maximum = receiveMaximumPointer
                raw_connect_options.maximum_packet_size_bytes = maximumPacketSizePointer

                return withOptionalCStructPointer(to: self.will) { willCPointer in
                    raw_connect_options.will = willCPointer

                    return withByteCursorFromStrings(clientId) { cClientId in
                        raw_connect_options.client_id = cClientId

                        // handle user property
                        return withOptionalUserPropertyArray(of: userProperties) { cUserProperties in
                            if let cUserProperties = cUserProperties {
                                raw_connect_options.user_property_count = userProperties!.count
                                raw_connect_options.user_properties = UnsafePointer<aws_mqtt5_user_property>(cUserProperties)
                            }
                            return withOptionalByteCursorPointerFromStrings(
                                username, password) { cUsernamePointer, cPasswordPointer in
                                    raw_connect_options.username = cUsernamePointer
                                    raw_connect_options.password = cPasswordPointer
                                    return body(raw_connect_options)
                                }
                        }
                    }
                }
            }
    }
}

/// Configuration for the creation of MQTT5 clients
public class MqttClientOptions: CStructWithUserData {
    /// Host name of the MQTT server to connect to.
    public let hostName: String

    /// Network port of the MQTT server to connect to.
    public let port: UInt32

    /// The Client bootstrap used
    public let bootstrap: ClientBootstrap

    /// The socket properties of the underlying MQTT connections made by the client or None if defaults are used.
    public let socketOptions: SocketOptions

    /// The TLS context for secure socket connections. If None, then a plaintext connection will be used.
    public let tlsCtx: TLSContext?

    /// The (tunneling) HTTP proxy usage when establishing MQTT connections
    public let httpProxyOptions: HTTPProxyOptions?

    /// This callback allows a custom transformation of the HTTP request that acts as the websocket handshake. Websockets will be used if this is set to a valid transformation callback.  To use websockets but not perform a transformation, just set this as a trivial completion callback.  If None, the connection will be made with direct MQTT.
    public let onWebsocketTransform: OnWebSocketHandshakeIntercept?

    /// All configurable options with respect to the CONNECT packet sent by the client, including the will. These connect properties will be used for every connection attempt made by the client.
    public let connectOptions: MqttConnectOptions?

    /// How the MQTT5 client should behave with respect to MQTT sessions.
    public let sessionBehavior: ClientSessionBehaviorType?

    /// The additional controls for client behavior with respect to operation validation and flow control; these checks go beyond the base MQTT5 spec to respect limits of specific MQTT brokers.
    public let extendedValidationAndFlowControlOptions: ExtendedValidationAndFlowControlOptions?

    /// Returns how disconnects affect the queued and in-progress operations tracked by the client.  Also controls how new operations are handled while the client is not connected.  In particular, if the client is not connected, then any operation that would be failed on disconnect (according to these rules) will also be rejected.
    public let offlineQueueBehavior: ClientOperationQueueBehaviorType?

    /// How the reconnect delay is modified in order to smooth out the distribution of reconnection attempt timepoints for a large set of reconnecting clients.
    public let retryJitterMode: ExponentialBackoffJitterMode?

    /// The minimum amount of time to wait to reconnect after a disconnect. Exponential backoff is performed with jitter after each connection failure.
    public let minReconnectDelay: TimeInterval?

    /// The maximum amount of time to wait to reconnect after a disconnect.  Exponential backoff is performed with jitter after each connection failure.
    public let maxReconnectDelay: TimeInterval?

    /// The amount of time that must elapse with an established connection before the reconnect delay is reset to the minimum. This helps alleviate bandwidth-waste in fast reconnect cycles due to permission failures on operations.
    public let minConnectedTimeToResetReconnectDelay: TimeInterval?

    /// The time interval to wait after sending a PINGREQ for a PINGRESP to arrive. If one does not arrive, the client will close the current connection.
    public let pingTimeout: TimeInterval?

    /// The time interval to wait after sending a CONNECT request for a CONNACK to arrive.  If one does not arrive, the connection will be shut down.
    public let connackTimeout: TimeInterval?

    /// The time interval to wait in whole seconds for an ack after sending a QoS 1+ PUBLISH, SUBSCRIBE, or UNSUBSCRIBE before failing the operation.
    public let ackTimeout: TimeInterval?

    /// All configurable options with respect to client topic aliasing behavior.
    public let topicAliasingOptions: TopicAliasingOptions?

    /// Callback for all publish packets received by client.
    public let onPublishReceivedFn: OnPublishReceived?

    /// Callback for Lifecycle Event Stopped.
    public let onLifecycleEventStoppedFn: OnLifecycleEventStopped?

    /// Callback for Lifecycle Event Attempting Connect.
    public let onLifecycleEventAttemptingConnectFn: OnLifecycleEventAttemptingConnect?

    /// Callback for Lifecycle Event Connection Success.
    public let onLifecycleEventConnectionSuccessFn: OnLifecycleEventConnectionSuccess?

    /// Callback for Lifecycle Event Connection Failure.
    public let onLifecycleEventConnectionFailureFn: OnLifecycleEventConnectionFailure?

    /// Callback for Lifecycle Event Disconnection.
    public let onLifecycleEventDisconnectionFn: OnLifecycleEventDisconnection?

    public init (
        hostName: String,
        port: UInt32,
        bootstrap: ClientBootstrap? = nil,
        socketOptions: SocketOptions? = nil,
        tlsCtx: TLSContext? = nil,
        onWebsocketTransform: OnWebSocketHandshakeIntercept? = nil,
        httpProxyOptions: HTTPProxyOptions? = nil,
        connectOptions: MqttConnectOptions? = nil,
        sessionBehavior: ClientSessionBehaviorType? = nil,
        extendedValidationAndFlowControlOptions: ExtendedValidationAndFlowControlOptions? = nil,
        offlineQueueBehavior: ClientOperationQueueBehaviorType? = nil,
        retryJitterMode: ExponentialBackoffJitterMode? = nil,
        minReconnectDelay: TimeInterval? = nil,
        maxReconnectDelay: TimeInterval? = nil,
        minConnectedTimeToResetReconnectDelay: TimeInterval? = nil,
        pingTimeout: TimeInterval? = nil,
        connackTimeout: TimeInterval? = nil,
        ackTimeout: TimeInterval? = nil,
        topicAliasingOptions: TopicAliasingOptions? = nil,
        onPublishReceivedFn: OnPublishReceived? = nil,
        onLifecycleEventStoppedFn: OnLifecycleEventStopped? = nil,
        onLifecycleEventAttemptingConnectFn: OnLifecycleEventAttemptingConnect? = nil,
        onLifecycleEventConnectionSuccessFn: OnLifecycleEventConnectionSuccess? = nil,
        onLifecycleEventConnectionFailureFn: OnLifecycleEventConnectionFailure? = nil,
        onLifecycleEventDisconnectionFn: OnLifecycleEventDisconnection? = nil) {

            self.hostName = hostName
            self.port = port
            // TODO currently Swift SDK creates its own static bootstrap at the SDK level.
            // TODO We probably want to create a static bootstrap at the CRT level. This will require
            // TODO some coordination with the existing Swift SDK. We need to not break them and insure
            // TODO we are cleaning up all static bootstrap related resources. This will be done at the point
            // TODO we are implementing the IoT Device SDK.
            if bootstrap == nil {
                do {
                    let elg = try EventLoopGroup()
                    let resolver = try HostResolver.makeDefault(eventLoopGroup: elg)
                    self.bootstrap = try ClientBootstrap(eventLoopGroup: elg, hostResolver: resolver)
                } catch {
                    fatalError("Bootstrap creation failure")
                }
            } else { self.bootstrap = bootstrap! }

            self.socketOptions = socketOptions ?? SocketOptions()
            self.tlsCtx = tlsCtx
            self.onWebsocketTransform = onWebsocketTransform
            self.httpProxyOptions = httpProxyOptions
            self.connectOptions = connectOptions
            self.sessionBehavior = sessionBehavior
            self.extendedValidationAndFlowControlOptions = extendedValidationAndFlowControlOptions
            self.offlineQueueBehavior = offlineQueueBehavior
            self.retryJitterMode = retryJitterMode
            self.minReconnectDelay = minReconnectDelay
            self.maxReconnectDelay = maxReconnectDelay
            self.minConnectedTimeToResetReconnectDelay = minConnectedTimeToResetReconnectDelay
            self.pingTimeout = pingTimeout
            self.connackTimeout = connackTimeout
            self.ackTimeout = ackTimeout
            self.topicAliasingOptions = topicAliasingOptions
            self.onPublishReceivedFn = onPublishReceivedFn
            self.onLifecycleEventStoppedFn = onLifecycleEventStoppedFn
            self.onLifecycleEventAttemptingConnectFn = onLifecycleEventAttemptingConnectFn
            self.onLifecycleEventConnectionSuccessFn = onLifecycleEventConnectionSuccessFn
            self.onLifecycleEventConnectionFailureFn = onLifecycleEventConnectionFailureFn
            self.onLifecycleEventDisconnectionFn = onLifecycleEventDisconnectionFn
        }

    func validateConversionToNative() throws {
        if let connectOptions {
            try connectOptions.validateConversionToNative()
        }

        do {
            _ = try minReconnectDelay?.millisecondUInt64()
        } catch {
            throw MqttError.validation(message: "Invalid minReconnectDelay value")
        }

        do {
            _ = try maxReconnectDelay?.millisecondUInt64()
        } catch {
            throw MqttError.validation(message: "Invalid maxReconnectDelay value")
        }

        do {
            _ = try minConnectedTimeToResetReconnectDelay?.millisecondUInt64()
        } catch {
            throw MqttError.validation(message: "Invalid minConnectedTimeToResetReconnectDelay value")
        }

        do {
            _ = try pingTimeout?.millisecondUInt32()
        } catch {
            throw MqttError.validation(message: "Invalid pingTimeout value")
        }

        do {
            _ = try connackTimeout?.millisecondUInt32()
        } catch {
            throw MqttError.validation(message: "Invalid connackTimeout value")
        }

        if let ackTimeout {
            if ackTimeout < 0 || ackTimeout > Double(UInt32.max) {
                throw MqttError.validation(message: "Invalid ackTimeout value")
            }
        }
    }

    typealias RawType = aws_mqtt5_client_options
    func withCStruct<Result>(userData: UnsafeMutableRawPointer?, _ body: (aws_mqtt5_client_options) -> Result) -> Result {
        var raw_options = aws_mqtt5_client_options()

        raw_options.port = self.port
        raw_options.bootstrap = self.bootstrap.rawValue

        var tls_options: TLSConnectionOptions?
        if self.tlsCtx != nil {
            tls_options = TLSConnectionOptions(context: self.tlsCtx!)
        }

        if let sessionBehavior = self.sessionBehavior {
            raw_options.session_behavior = sessionBehavior.rawValue
        }

        if let extendedValidationAndFlowControlOptions = self.extendedValidationAndFlowControlOptions {
            raw_options.extended_validation_and_flow_control_options = extendedValidationAndFlowControlOptions.rawValue
        }

        if let offlineQueueBehavior = self.offlineQueueBehavior {
            raw_options.offline_queue_behavior = offlineQueueBehavior.rawValue
        }

        if let retryJitterMode = self.retryJitterMode {
            raw_options.retry_jitter_mode = retryJitterMode.rawValue
        }

        if let minReconnectDelay = self.minReconnectDelay {
            raw_options.min_reconnect_delay_ms = minReconnectDelay.millisecond
        }

        if let maxReconnectDelay = self.maxReconnectDelay {
            raw_options.max_reconnect_delay_ms = maxReconnectDelay.millisecond
        }

        if let minConnectedTimeToResetReconnectDelay = self.minConnectedTimeToResetReconnectDelay {
            raw_options.min_connected_time_to_reset_reconnect_delay_ms =
            minConnectedTimeToResetReconnectDelay.millisecond
        }

        if let pingTimeout = self.pingTimeout {
            raw_options.ping_timeout_ms = UInt32((pingTimeout*1_000).rounded())
        }

        if let connackTimeout = self.connackTimeout {
            raw_options.connack_timeout_ms = UInt32((connackTimeout*1_000).rounded())
        }

        if let ackTimeout = self.ackTimeout {
            raw_options.ack_timeout_seconds = UInt32(ackTimeout)
        }

        // We assign a default connection option if options is not set
        var connnectOptions = self.connectOptions
        if connnectOptions == nil {
            connnectOptions =  MqttConnectOptions()
        }

        return withOptionalCStructPointer(
            self.socketOptions,
            tls_options,
            self.httpProxyOptions,
            self.topicAliasingOptions,
            connnectOptions) { socketOptionsCPointer,
                               tlsOptionsCPointer,
                               httpProxyOptionsCPointer,
                               topicAliasingOptionsCPointer,
                               connectOptionsCPointer in

                raw_options.socket_options = socketOptionsCPointer
                raw_options.tls_options = tlsOptionsCPointer
                raw_options.http_proxy_options = httpProxyOptionsCPointer
                raw_options.topic_aliasing_options = topicAliasingOptionsCPointer
                raw_options.connect_options = connectOptionsCPointer

                guard let userData else {
                    // directly return
                    return hostName.withByteCursor { hostNameByteCursor in
                        raw_options.host_name = hostNameByteCursor
                        return body(raw_options)
                    }
                }

                if self.onWebsocketTransform != nil {
                    raw_options.websocket_handshake_transform = MqttClientWebsocketTransform
                    raw_options.websocket_handshake_transform_user_data = userData
                }

                raw_options.lifecycle_event_handler = MqttClientLifeycyleEvents
                raw_options.lifecycle_event_handler_user_data = userData
                raw_options.publish_received_handler = MqttClientPublishRecievedEvents
                raw_options.publish_received_handler_user_data = userData
                raw_options.client_termination_handler = MqttClientTerminationCallback
                raw_options.client_termination_handler_user_data = userData
                return hostName.withByteCursor { hostNameByteCursor in
                    raw_options.host_name = hostNameByteCursor
                    return body(raw_options)
                }
            }
    }
}

/// Mqtt behavior settings that are dynamically negotiated as part of the CONNECT/CONNACK exchange.
/// While you can infer all of these values from a combination of:
/// - defaults as specified in the mqtt5 spec
/// - your CONNECT settings
/// - the CONNACK from the broker
/// the client instead does the combining for you and emits a NegotiatedSettings object with final, authoritative values.
/// Negotiated settings are communicated with every successful connection establishment.
public class NegotiatedSettings {

    /// The maximum QoS allowed for publishes on this connection instance
    public let maximumQos: QoS

    /// The amount of time in whole seconds the server will retain the MQTT session after a disconnect.
    public let sessionExpiryInterval: TimeInterval

    /// The number of in-flight QoS 1 and QoS 2 publications the server is willing to process concurrently.
    public let receiveMaximumFromServer: UInt16

    /// The maximum packet size the server is willing to accept.
    public let maximumPacketSizeToServer: UInt32

    /// The maximum allowed topic alias value on publishes sent from client to server
    public let topicAliasMaximumToServer: UInt16

    /// The maximum allowed topic alias value on publishes sent from server to client
    public let topicAliasMaximumToClient: UInt16

    /// The maximum amount of time in whole seconds between client packets. The client will use PINGREQs to ensure this limit is not breached.  The server will disconnect the client for inactivity if no MQTT packet is received in a time interval equal to 1.5 x this value.
    public let serverKeepAlive: TimeInterval

    /// Whether the server supports retained messages.
    public let retainAvailable: Bool

    /// Whether the server supports wildcard subscriptions.
    public let wildcardSubscriptionsAvailable: Bool

    /// Whether the server supports subscription identifiers
    public let subscriptionIdentifiersAvailable: Bool

    /// Whether the server supports shared subscriptions
    public let sharedSubscriptionsAvailable: Bool

    /// Whether the client has rejoined an existing session.
    public let rejoinedSession: Bool

    /// The final client id in use by the newly-established connection.  This will be the configured client id if one was given in the configuration, otherwise, if no client id was specified, this will be the client id assigned by the server.  Reconnection attempts will always use the auto-assigned client id, allowing for auto-assigned session resumption.
    public let clientId: String

    internal init(_ settings: UnsafePointer<aws_mqtt5_negotiated_settings>){
        let negotiatedSettings = settings.pointee
        self.maximumQos = QoS(negotiatedSettings.maximum_qos)
        self.sessionExpiryInterval = TimeInterval(negotiatedSettings.session_expiry_interval)
        self.receiveMaximumFromServer = negotiatedSettings.receive_maximum_from_server
        self.maximumPacketSizeToServer = negotiatedSettings.maximum_packet_size_to_server
        self.topicAliasMaximumToServer = negotiatedSettings.topic_alias_maximum_to_server
        self.topicAliasMaximumToClient = negotiatedSettings.topic_alias_maximum_to_client
        self.serverKeepAlive = TimeInterval(negotiatedSettings.server_keep_alive)
        self.retainAvailable = negotiatedSettings.retain_available
        self.wildcardSubscriptionsAvailable = negotiatedSettings.wildcard_subscriptions_available
        self.subscriptionIdentifiersAvailable = negotiatedSettings.subscription_identifiers_available
        self.sharedSubscriptionsAvailable = negotiatedSettings.shared_subscriptions_available
        self.rejoinedSession = negotiatedSettings.rejoined_session
        self.clientId = negotiatedSettings.client_id_storage.toString()
    }
}
