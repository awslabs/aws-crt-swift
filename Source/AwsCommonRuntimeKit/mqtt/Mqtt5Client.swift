///  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
///  SPDX-License-Identifier: Apache-2.0.

import Foundation
import AwsCMqtt
import AwsCIo

// MARK: - Client Options

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
            self.maximumPacketSize) { (sessionExpiryIntervalSecPointer, requestResponseInformationPointer,
                                       requestProblemInformationPointer, willDelayIntervalSecPointer,
                                       receiveMaximumPointer, maximumPacketSizePointer) in

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
            connnectOptions) { (socketOptionsCPointer, tlsOptionsCPointer,
                                 httpProxyOptionsCPointer, topicAliasingOptionsCPointer,
                                 connectOptionsCPointer) in

                raw_options.socket_options = socketOptionsCPointer
                raw_options.tls_options = tlsOptionsCPointer
                raw_options.http_proxy_options = httpProxyOptionsCPointer
                raw_options.topic_aliasing_options = topicAliasingOptionsCPointer
                raw_options.connect_options = connectOptionsCPointer

                guard let _userData = userData else {
                    // directly return
                    return hostName.withByteCursor { hostNameByteCursor in
                        raw_options.host_name = hostNameByteCursor
                        return body(raw_options)
                    }
                }

                if self.onWebsocketTransform != nil {
                    raw_options.websocket_handshake_transform = MqttClientWebsocketTransform
                    raw_options.websocket_handshake_transform_user_data = _userData
                }

                raw_options.lifecycle_event_handler = MqttClientLifeycyleEvents
                raw_options.lifecycle_event_handler_user_data = _userData
                raw_options.publish_received_handler = MqttClientPublishRecievedEvents
                raw_options.publish_received_handler_user_data = _userData
                raw_options.client_termination_handler = MqttClientTerminationCallback
                raw_options.client_termination_handler_user_data = _userData
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

    public init (maximumQos: QoS,
                 sessionExpiryInterval: TimeInterval,
                 receiveMaximumFromServer: UInt16,
                 maximumPacketSizeToServer: UInt32,
                 topicAliasMaximumToServer: UInt16,
                 topicAliasMaximumToClient: UInt16,
                 serverKeepAlive: TimeInterval,
                 retainAvailable: Bool,
                 wildcardSubscriptionsAvailable: Bool,
                 subscriptionIdentifiersAvailable: Bool,
                 sharedSubscriptionsAvailable: Bool,
                 rejoinedSession: Bool,
                 clientId: String) {
        self.maximumQos = maximumQos
        self.sessionExpiryInterval = sessionExpiryInterval
        self.receiveMaximumFromServer = receiveMaximumFromServer
        self.maximumPacketSizeToServer = maximumPacketSizeToServer
        self.topicAliasMaximumToServer = topicAliasMaximumToServer
        self.topicAliasMaximumToClient = topicAliasMaximumToClient
        self.serverKeepAlive = serverKeepAlive
        self.retainAvailable = retainAvailable
        self.wildcardSubscriptionsAvailable = wildcardSubscriptionsAvailable
        self.subscriptionIdentifiersAvailable = subscriptionIdentifiersAvailable
        self.sharedSubscriptionsAvailable = sharedSubscriptionsAvailable
        self.rejoinedSession = rejoinedSession
        self.clientId = clientId
    }

    static func convertFromNative(_ from: UnsafePointer<aws_mqtt5_negotiated_settings>?) -> NegotiatedSettings? {

        guard let from else {
            return nil
        }

        let _negotiatedSettings = from.pointee
        let negotiatedMaximumQos = QoS(_negotiatedSettings.maximum_qos)
        let negotiatedSessionExpiryInterval: TimeInterval = TimeInterval(_negotiatedSettings.session_expiry_interval)
        let negotiatedReceiveMaximumFromServer = _negotiatedSettings.receive_maximum_from_server
        let negotiatedMaximumPacketSizeToServer = _negotiatedSettings.maximum_packet_size_to_server
        let negotiatedTopicAliasMaximumToServer = _negotiatedSettings.topic_alias_maximum_to_server
        let negotiatedTopicAliasMaximumToClient = _negotiatedSettings.topic_alias_maximum_to_client
        let negotiatedServerKeepAlive: TimeInterval = TimeInterval(_negotiatedSettings.server_keep_alive)
        let negotiatedRetainAvailable = _negotiatedSettings.retain_available
        let negotiatedWildcardSubscriptionsAvailable = _negotiatedSettings.wildcard_subscriptions_available
        let negotiatedSubscriptionIdentifiersAvailable = _negotiatedSettings.subscription_identifiers_available
        let negotiatedSharedSubscriptionsAvailable = _negotiatedSettings.shared_subscriptions_available
        let negotiatedRejoinedSession = _negotiatedSettings.rejoined_session
        let negotiatedClientId = _negotiatedSettings.client_id_storage.toString()

        let negotiatedSettings = NegotiatedSettings(
            maximumQos: negotiatedMaximumQos,
            sessionExpiryInterval: negotiatedSessionExpiryInterval,
            receiveMaximumFromServer: negotiatedReceiveMaximumFromServer,
            maximumPacketSizeToServer: negotiatedMaximumPacketSizeToServer,
            topicAliasMaximumToServer: negotiatedTopicAliasMaximumToServer,
            topicAliasMaximumToClient: negotiatedTopicAliasMaximumToClient,
            serverKeepAlive: negotiatedServerKeepAlive,
            retainAvailable: negotiatedRetainAvailable,
            wildcardSubscriptionsAvailable: negotiatedWildcardSubscriptionsAvailable,
            subscriptionIdentifiersAvailable: negotiatedSubscriptionIdentifiersAvailable,
            sharedSubscriptionsAvailable: negotiatedSharedSubscriptionsAvailable,
            rejoinedSession: negotiatedRejoinedSession,
            clientId: negotiatedClientId)

        return negotiatedSettings
    }
}

// MARK: - Callback Data Classes

/// Dataclass containing some simple statistics about the current state of the client's queue of operations
public class ClientOperationStatistics {

    /// Total number of operations submitted to the client that have not yet been completed.  Unacked operations are a subset of this.
    public let incompleteOperationCount: UInt64

    /// Total packet size of operations submitted to the client that have not yet been completed.  Unacked operations are a subset of this.
    public let incompleteOperationSize: UInt64

    /// Total number of operations that have been sent to the server and are waiting for a corresponding ACK before they can be completed.
    public let unackedOperationCount: UInt64

    /// Total packet size of operations that have been sent to the server and are waiting for a corresponding ACK before they can be completed.
    public let unackedOperationSize: UInt64

    public init (incompleteOperationCount: UInt64,
                 incompleteOperationSize: UInt64,
                 unackedOperationCount: UInt64,
                 unackedOperationSize: UInt64) {
        self.incompleteOperationCount = incompleteOperationCount
        self.incompleteOperationSize = incompleteOperationSize
        self.unackedOperationCount = unackedOperationCount
        self.unackedOperationSize = unackedOperationSize
    }
}

/// Class containing data related to a Publish Received Callback
public class PublishReceivedData {

    /// Data model of an `MQTT5 PUBLISH <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901100>`_ packet.
    public let publishPacket: PublishPacket

    public init (publishPacket: PublishPacket) {
        self.publishPacket = publishPacket
    }
}

/// Class containing results of an Stopped Lifecycle Event. Currently unused.
public class LifecycleStoppedData { }

/// Class containing results of an Attempting Connect Lifecycle Event. Currently unused.
public class LifecycleAttemptingConnectData { }

/// Class containing results of a Connect Success Lifecycle Event.
public class LifecycleConnectionSuccessData {

    /// Data model of an `MQTT5 CONNACK <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901074>`_ packet.
    public let connackPacket: ConnackPacket

    /// Mqtt behavior settings that have been dynamically negotiated as part of the CONNECT/CONNACK exchange.
    public let negotiatedSettings: NegotiatedSettings

    public init (connackPacket: ConnackPacket, negotiatedSettings: NegotiatedSettings) {
        self.connackPacket = connackPacket
        self.negotiatedSettings = negotiatedSettings
    }
}

/// Dataclass containing results of a Connect Failure Lifecycle Event.
public class LifecycleConnectionFailureData {

    /// Error which caused connection failure.
    public let crtError: CRTError

    /// Data model of an `MQTT5 CONNACK <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901074>`_ packet.
    public let connackPacket: ConnackPacket?

    public init (crtError: CRTError, connackPacket: ConnackPacket? = nil) {
        self.crtError = crtError
        self.connackPacket = connackPacket
    }
}

/// Dataclass containing results of a Disconnect Lifecycle Event
public class LifecycleDisconnectData {

    /// Error which caused disconnection.
    public let crtError: CRTError

    /// Data model of an `MQTT5 DISCONNECT <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901205>`_ packet.
    public let disconnectPacket: DisconnectPacket?

    public init (crtError: CRTError, disconnectPacket: DisconnectPacket? = nil) {
        self.crtError = crtError
        self.disconnectPacket = disconnectPacket
    }
}

// MARK: - Callback typealias definitions

/// Defines signature of the Publish callback
public typealias OnPublishReceived = (PublishReceivedData) -> Void

/// Defines signature of the Lifecycle Event Stopped callback
public typealias OnLifecycleEventStopped = (LifecycleStoppedData) -> Void

/// Defines signature of the Lifecycle Event Attempting Connect callback
public typealias OnLifecycleEventAttemptingConnect = (LifecycleAttemptingConnectData) -> Void

/// Defines signature of the Lifecycle Event Connection Success callback
public typealias OnLifecycleEventConnectionSuccess = (LifecycleConnectionSuccessData) -> Void

/// Defines signature of the Lifecycle Event Connection Failure callback
public typealias OnLifecycleEventConnectionFailure = (LifecycleConnectionFailureData) -> Void

/// Defines signature of the Lifecycle Event Disconnection callback
public typealias OnLifecycleEventDisconnection = (LifecycleDisconnectData) -> Void

/// Callback for users to invoke upon completion of, presumably asynchronous, OnWebSocketHandshakeIntercept callback's initiated process.
public typealias OnWebSocketHandshakeInterceptComplete = (HTTPRequestBase, Int32) -> Void

/// Invoked during websocket handshake to give users opportunity to transform an http request for purposes
/// such as signing/authorization etc... Returning from this function does not continue the websocket
/// handshake since some work flows may be asynchronous. To accommodate that, onComplete must be invoked upon
/// completion of the signing process.
public typealias OnWebSocketHandshakeIntercept = (HTTPRequest, @escaping OnWebSocketHandshakeInterceptComplete) -> Void

// MARK: - Mqtt5 Client
public class Mqtt5Client {
    private var rawValue: UnsafeMutablePointer<aws_mqtt5_client>?
    private var callbackCore: MqttCallbackCore

    init(clientOptions options: MqttClientOptions) throws {

        try options.validateConversionToNative()

        self.callbackCore = MqttCallbackCore(
            onPublishReceivedCallback: options.onPublishReceivedFn,
            onLifecycleEventStoppedCallback: options.onLifecycleEventStoppedFn,
            onLifecycleEventAttemptingConnect: options.onLifecycleEventAttemptingConnectFn,
            onLifecycleEventConnectionSuccess: options.onLifecycleEventConnectionSuccessFn,
            onLifecycleEventConnectionFailure: options.onLifecycleEventConnectionFailureFn,
            onLifecycleEventDisconnection: options.onLifecycleEventDisconnectionFn,
            onWebsocketInterceptor: options.onWebsocketTransform)

        guard let rawValue = (options.withCPointer(
            userData: self.callbackCore.callbackUserData()) { optionsPointer in
                return aws_mqtt5_client_new(allocator.rawValue, optionsPointer)
            }) else {
            // failed to create client, release the callback core
            self.callbackCore.release()
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        self.rawValue = rawValue
    }

    deinit {
        self.callbackCore.close()
        aws_mqtt5_client_release(rawValue)
    }

    public func start() throws {
        if rawValue != nil {
            let errorCode = aws_mqtt5_client_start(rawValue)

            if errorCode != AWS_OP_SUCCESS {
                throw CommonRunTimeError.crtError(CRTError(code: errorCode))
            }
        }
    }

    public func stop(disconnectPacket: DisconnectPacket? = nil) throws {
        if rawValue != nil {
            var errorCode: Int32 = 0

            if let disconnectPacket {
                try disconnectPacket.validateConversionToNative()

                disconnectPacket.withCPointer { disconnectPointer in
                    errorCode = aws_mqtt5_client_stop(rawValue, disconnectPointer, nil)
                }
            } else {
                errorCode = aws_mqtt5_client_stop(rawValue, nil, nil)
            }

            if errorCode != AWS_OP_SUCCESS {
                throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
            }
        }
    }

    /// Tells the client to attempt to subscribe to one or more topic filters.
    ///
    /// - Parameters:
    ///     - subscribePacket: SUBSCRIBE packet to send to the server
    /// - Returns:
    ///     - `SubackPacket`: return Suback packet if the subscription operation succeeded
    ///
    /// - Throws: CommonRuntimeError.crtError
    public func subscribe(subscribePacket: SubscribePacket) async throws -> SubackPacket {

        return try await withCheckedThrowingContinuation { continuation in
            subscribePacket.withCPointer { subscribePacketPointer in
                var callbackOptions = aws_mqtt5_subscribe_completion_options()
                let continuationCore = ContinuationCore(continuation: continuation)
                callbackOptions.completion_callback = subscribeCompletionCallback
                callbackOptions.completion_user_data = continuationCore.passRetained()
                let result = aws_mqtt5_client_subscribe(rawValue, subscribePacketPointer, &callbackOptions)
                guard result == AWS_OP_SUCCESS else {
                    continuationCore.release()
                    return continuation.resume(throwing: CommonRunTimeError.crtError(CRTError.makeFromLastError()))
                }
            }

        }
    }

    /// Tells the client to attempt to publish to topic filter.
    ///
    /// - Parameters:
    ///     - publishPacket: PUBLISH packet to send to the server
    /// - Returns:
    ///     - For qos 0 packet: return `None` if publish succeeded
    ///     - For qos 1 packet: return `PublishResult` packet if the publish succeeded
    ///
    /// - Throws: CommonRuntimeError.crtError
    public func publish(publishPacket: PublishPacket) async throws -> PublishResult {

        try publishPacket.validateConversionToNative()

        return try await withCheckedThrowingContinuation { continuation in

            publishPacket.withCPointer { publishPacketPointer in
                var callbackOptions = aws_mqtt5_publish_completion_options()
                let continuationCore = ContinuationCore<PublishResult>(continuation: continuation)
                callbackOptions.completion_callback = publishCompletionCallback
                callbackOptions.completion_user_data = continuationCore.passRetained()
                let result = aws_mqtt5_client_publish(rawValue, publishPacketPointer, &callbackOptions)
                if result != AWS_OP_SUCCESS {
                    continuationCore.release()
                    return continuation.resume(throwing: CommonRunTimeError.crtError(CRTError.makeFromLastError()))
                }
            }
        }
    }

    /// Tells the client to attempt to unsubscribe to one or more topic filters.
    ///
    /// - Parameters:
    ///     - unsubscribePacket: UNSUBSCRIBE packet to send to the server
    /// - Returns:
    ///     - `UnsubackPacket`: return Unsuback packet if the unsubscribe operation succeeded
    ///
    /// - Throws: CommonRuntimeError.crtError
    public func unsubscribe(unsubscribePacket: UnsubscribePacket) async throws -> UnsubackPacket {

        return try await withCheckedThrowingContinuation { continuation in

            unsubscribePacket.withCPointer { unsubscribePacketPointer in
                var callbackOptions = aws_mqtt5_unsubscribe_completion_options()
                let continuationCore = ContinuationCore(continuation: continuation)
                callbackOptions.completion_callback = unsubscribeCompletionCallback
                callbackOptions.completion_user_data = continuationCore.passRetained()
                let result = aws_mqtt5_client_unsubscribe(rawValue, unsubscribePacketPointer, &callbackOptions)
                guard result == AWS_OP_SUCCESS else {
                    continuationCore.release()
                    return continuation.resume(throwing: CommonRunTimeError.crtError(CRTError.makeFromLastError()))
                }
            }
        }
    }

    public func close() {
        self.callbackCore.close()
        aws_mqtt5_client_release(rawValue)
        rawValue = nil
    }
}

// MARK: - Private

/// Handles lifecycle events from native Mqtt Client
private func MqttClientLifeycyleEvents(_ lifecycleEvent: UnsafePointer<aws_mqtt5_client_lifecycle_event>?) {

    guard let lifecycleEvent: UnsafePointer<aws_mqtt5_client_lifecycle_event> = lifecycleEvent else {
        fatalError("MqttClientLifecycleEvents was called from native without an aws_mqtt5_client_lifecycle_event.")
    }

    let crtError = CRTError(code: lifecycleEvent.pointee.error_code)

    if let userData = lifecycleEvent.pointee.user_data {
        let callbackCore: MqttCallbackCore = Unmanaged<MqttCallbackCore>.fromOpaque(userData).takeUnretainedValue()

        // validate the callback flag, if flag is false, return
        callbackCore.rwlock.read {
            if callbackCore.callbackFlag == false { return }

            switch lifecycleEvent.pointee.event_type {
            case AWS_MQTT5_CLET_ATTEMPTING_CONNECT:

                let lifecycleAttemptingConnectData = LifecycleAttemptingConnectData()
                callbackCore.onLifecycleEventAttemptingConnect(lifecycleAttemptingConnectData)

            case AWS_MQTT5_CLET_CONNECTION_SUCCESS:

                guard let connackPacket = ConnackPacket.convertFromNative(lifecycleEvent.pointee.connack_data) else {
                    fatalError("ConnackPacket missing in a Connection Success lifecycle event.")
                }

                guard let negotiatedSettings = NegotiatedSettings.convertFromNative(lifecycleEvent.pointee.settings) else {
                    fatalError("NegotiatedSettings missing in a Connection Success lifecycle event.")
                }

                let lifecycleConnectionSuccessData = LifecycleConnectionSuccessData(
                    connackPacket: connackPacket,
                    negotiatedSettings: negotiatedSettings)
                callbackCore.onLifecycleEventConnectionSuccess(lifecycleConnectionSuccessData)

            case AWS_MQTT5_CLET_CONNECTION_FAILURE:

                let connackPacket = ConnackPacket.convertFromNative(lifecycleEvent.pointee.connack_data)

                let lifecycleConnectionFailureData = LifecycleConnectionFailureData(
                    crtError: crtError,
                    connackPacket: connackPacket)
                callbackCore.onLifecycleEventConnectionFailure(lifecycleConnectionFailureData)

            case AWS_MQTT5_CLET_DISCONNECTION:

                guard let disconnectPacket = DisconnectPacket.convertFromNative(lifecycleEvent.pointee.disconnect_data) else {
                    let lifecycleDisconnectData = LifecycleDisconnectData(crtError: crtError)
                    callbackCore.onLifecycleEventDisconnection(lifecycleDisconnectData)
                    return
                }

                let lifecycleDisconnectData = LifecycleDisconnectData(
                        crtError: crtError,
                        disconnectPacket: disconnectPacket)
                callbackCore.onLifecycleEventDisconnection(lifecycleDisconnectData)

            case AWS_MQTT5_CLET_STOPPED:

                callbackCore.onLifecycleEventStoppedCallback(LifecycleStoppedData())

            default:
                fatalError("A lifecycle event with an invalid event type was encountered.")
            }
        }

    }
}

private func MqttClientPublishRecievedEvents(
    _ publishPacketView: UnsafePointer<aws_mqtt5_packet_publish_view>?,
    _ userData: UnsafeMutableRawPointer?) {
    let callbackCore = Unmanaged<MqttCallbackCore>.fromOpaque(userData!).takeUnretainedValue()

    // validate the callback flag, if flag is false, return
    callbackCore.rwlock.read {
        if callbackCore.callbackFlag == false { return }

        guard let publish_packet = PublishPacket.convertFromNative(publishPacketView) else {
            fatalError("NegotiatedSettings missing in a Connection Success lifecycle event.")
        }
        let puback = PublishReceivedData(publishPacket: publish_packet)
        callbackCore.onPublishReceivedCallback(puback)
    }
}

private func MqttClientWebsocketTransform(
    _ rawHttpMessage: OpaquePointer?,
    _ userData: UnsafeMutableRawPointer?,
    _ completeFn: (@convention(c) (OpaquePointer?, Int32, UnsafeMutableRawPointer?) -> Void)?,
    _ completeCtx: UnsafeMutableRawPointer?) {

    let callbackCore = Unmanaged<MqttCallbackCore>.fromOpaque(userData!).takeUnretainedValue()

    // validate the callback flag, if flag is false, return
    callbackCore.rwlock.read {
        if callbackCore.callbackFlag == false { return }

        guard let rawHttpMessage else {
            fatalError("Null HttpRequeset in websocket transform function.")
        }
        let httpRequest = HTTPRequest(nativeHttpMessage: rawHttpMessage)
        @Sendable func signerTransform(request: HTTPRequestBase, errorCode: Int32) {
            completeFn?(request.rawValue, errorCode, completeCtx)
        }

        if callbackCore.onWebsocketInterceptor != nil {
            callbackCore.onWebsocketInterceptor!(httpRequest, signerTransform)
        }
    }
}

private func MqttClientTerminationCallback(_ userData: UnsafeMutableRawPointer?) {
    // termination callback
    print("[Mqtt5 Client Swift] TERMINATION CALLBACK")
    // takeRetainedValue would release the reference. ONLY DO IT AFTER YOU DO NOT NEED THE CALLBACK CORE
    _ = Unmanaged<MqttCallbackCore>.fromOpaque(userData!).takeRetainedValue()
}

/// The completion callback to invoke when subscribe operation completes in native
private func subscribeCompletionCallback(subackPacket: UnsafePointer<aws_mqtt5_packet_suback_view>?,
                                         errorCode: Int32,
                                         userData: UnsafeMutableRawPointer?) {
    let continuationCore = Unmanaged<ContinuationCore<SubackPacket>>.fromOpaque(userData!).takeRetainedValue()

    guard errorCode == AWS_OP_SUCCESS else {
        return continuationCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
    }

    guard let suback = SubackPacket.convertFromNative(subackPacket) else {
        fatalError("Suback missing in the subscription completion callback.")
    }

    continuationCore.continuation.resume(returning: suback)
}

/// The completion callback to invoke when publish operation completes in native
private func publishCompletionCallback(packet_type: aws_mqtt5_packet_type,
                                       navtivePublishResult: UnsafeRawPointer?,
                                       errorCode: Int32,
                                       userData: UnsafeMutableRawPointer?) {
    let continuationCore = Unmanaged<ContinuationCore<PublishResult>>.fromOpaque(userData!).takeRetainedValue()

    if errorCode != AWS_OP_SUCCESS {
        return continuationCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
    }

    switch packet_type {
    case AWS_MQTT5_PT_NONE:     // QoS0
        return continuationCore.continuation.resume(returning: PublishResult())
    case AWS_MQTT5_PT_PUBACK:   // QoS1
        guard let puback = navtivePublishResult?.assumingMemoryBound(
            to: aws_mqtt5_packet_puback_view.self) else {
            return continuationCore.continuation.resume(
                throwing: CommonRunTimeError.crtError(CRTError.makeFromLastError()))
            }
        let publishResult = PublishResult(puback: PubackPacket.convertFromNative(puback))
        return continuationCore.continuation.resume(returning: publishResult)
    default:
        return continuationCore.continuation.resume(
            throwing: CommonRunTimeError.crtError(CRTError(code: AWS_ERROR_UNKNOWN.rawValue)))
    }
}

/// The completion callback to invoke when unsubscribe operation completes in native
private func unsubscribeCompletionCallback(unsubackPacket: UnsafePointer<aws_mqtt5_packet_unsuback_view>?,
                                           errorCode: Int32,
                                           userData: UnsafeMutableRawPointer?) {
    let continuationCore = Unmanaged<ContinuationCore<UnsubackPacket>>.fromOpaque(userData!).takeRetainedValue()

    guard errorCode == AWS_OP_SUCCESS else {
        return continuationCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
    }

    guard let unsuback = UnsubackPacket.convertFromNative(unsubackPacket) else {
        fatalError("Unsuback missing in the Unsubscribe completion callback.")
    }

    continuationCore.continuation.resume(returning: unsuback)
}

/// When the native client calls swift callbacks they are processed through the MqttCallbackCore
private class MqttCallbackCore {
    let onPublishReceivedCallback: OnPublishReceived
    let onLifecycleEventStoppedCallback: OnLifecycleEventStopped
    let onLifecycleEventAttemptingConnect: OnLifecycleEventAttemptingConnect
    let onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess
    let onLifecycleEventConnectionFailure: OnLifecycleEventConnectionFailure
    let onLifecycleEventDisconnection: OnLifecycleEventDisconnection
    // The websocket interceptor could be nil if the websocket is not in use
    let onWebsocketInterceptor: OnWebSocketHandshakeIntercept?

    let rwlock = ReadWriteLock()
    var callbackFlag = true

    init(onPublishReceivedCallback: OnPublishReceived? = nil,
         onLifecycleEventStoppedCallback: OnLifecycleEventStopped? = nil,
         onLifecycleEventAttemptingConnect: OnLifecycleEventAttemptingConnect? = nil,
         onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess? = nil,
         onLifecycleEventConnectionFailure: OnLifecycleEventConnectionFailure? = nil,
         onLifecycleEventDisconnection: OnLifecycleEventDisconnection? = nil,
         onWebsocketInterceptor: OnWebSocketHandshakeIntercept? = nil,
         data: AnyObject? = nil) {

        self.onPublishReceivedCallback = onPublishReceivedCallback ?? { (_) in return }
        self.onLifecycleEventStoppedCallback = onLifecycleEventStoppedCallback ?? { (_) in return}
        self.onLifecycleEventAttemptingConnect = onLifecycleEventAttemptingConnect ?? { (_) in return}
        self.onLifecycleEventConnectionSuccess = onLifecycleEventConnectionSuccess ?? { (_) in return}
        self.onLifecycleEventConnectionFailure = onLifecycleEventConnectionFailure ?? { (_) in return}
        self.onLifecycleEventDisconnection = onLifecycleEventDisconnection ?? { (_) in return}
        self.onWebsocketInterceptor = onWebsocketInterceptor
    }

    /// Calling this function performs a manual retain on the MqttShutdownCallbackCore.
    /// and returns the UnsafeMutableRawPointer hold the object itself.
    ///
    /// You should always release the retained pointer to avoid memory leak
    func callbackUserData() -> UnsafeMutableRawPointer {
        return Unmanaged<MqttCallbackCore>.passRetained(self).toOpaque()
    }

    func release() {
        close()
        Unmanaged<MqttCallbackCore>.passUnretained(self).release()
    }

    func close() {
        rwlock.write {
            self.callbackFlag = false
        }
    }
}