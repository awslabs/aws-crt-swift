//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCHttp

/// Stream manager configuration struct.
/// Contains all of the configuration needed to create an http connection as well as
/// the maximum number of connections to ever have in existence.
public struct HTTP2StreamManagerOptions: CStructWithShutdownOptions {

    /// The client bootstrap instance to use to create the pool's connections
    public var clientBootstrap: ClientBootstrap
    /// The host name to use for connections in the connection pool
    public var hostName: String

    /// The port to connect to for connections in the connection pool
    public var port: UInt16
    /// The proxy options for connections in the connection pool
    public var proxyOptions: HTTPProxyOptions?
    /// Configuration for using proxy from environment variable. Only works when proxyOptions is not set.
    public var proxyEnvSettings: HTTPProxyEnvSettings?
    /// The socket options to use for connections in the connection pool
    public var socketOptions: SocketOptions
    /// The tls options to use for connections in the connection pool
    public var tlsOptions: TLSConnectionOptions?

    /// HTTP/2 Stream window control.
    /// If set to true, the read back pressure mechanism will be enabled for streams created.
    /// The initial window size can be set by `initialWindowSize` via `http2InitialSettings`
    public var enableStreamManualWindowManagement: Bool

    /// Max connections the manager can contain
    public var maxConnections: Int

    /// Add a shut down callback using these options
    public var shutdownCallback: ShutdownCallback?

    public var monitoringOptions: HTTPMonitoringOptions?

    /// Specify whether you have prior knowledge that cleartext (HTTP) connections are HTTP/2 (RFC-7540 3.4).
    /// If false, then cleartext connections are treated as HTTP/1.1.
    /// It is illegal to set this true when secure connections are being used.
    /// Note that upgrading from HTTP/1.1 to HTTP/ 2 is not supported (RFC-7540 3.2).
    public var priorKnowledge: Bool

    /// The data of settings to change for initial settings.
    /// Note: each setting has its boundary.
    public var initialSettings: HTTP2Settings?

    /// The max number of recently-closed streams to remember.
    /// Set it to nil to use the default setting
    ///
    /// If the connection receives a frame for a closed stream,
    /// the frame will be ignored or cause a connection error,
    /// depending on the frame type and how the stream was closed.
    /// Remembering more streams reduces the chances that a late frame causes
    /// a connection error, but costs some memory.
    public var maxClosedStreams: Int?

    /// Connection level window control
    /// Set to true to manually manage the flow-control window of whole HTTP/2 connection.
    ///
    /// If false, the connection will maintain its flow-control windows such that
    /// no back-pressure is applied and data arrives as fast as possible.
    ///
    /// If true, the flow-control window of the whole connection will shrink as body data
    /// is received (headers, padding, and other metadata do not affect the window) for every streams
    /// created on this connection.
    /// The initial connection flow-control window is 65,535. It is not controllable.
    /// Once the connection's flow-control window reaches to 0, all the streams on the connection stop receiving any
    /// further data.
    /// The user must call aws_http2_connection_update_window() to increment the connection's // TODO: update
    /// window and keep data flowing.
    /// Note: the padding of data frame counts to the flow-control window.
    /// But, the client will always automatically update the window for padding even for manual window update.
    public var enableConnectionManualWindowManagement: Bool

    /// (Optional)
    /// When set, connection will be closed if 5xx response received from server.
    public var closeConnectionOnServerError: Bool

    /// (Optional)
    /// The period for all the connections held by stream manager to send a PING in milliseconds.
    /// If you specify Nil, manager will NOT send any PING.
    /// Note: if set, it must be large than the time of ping timeout setting.
    public var connectionPingPeriodMs: Int?

    /// (Optional)
    /// Network connection will be closed if a ping response is not received
    /// within this amount of time (milliseconds).
    public var connectionPingTimeoutMs: Int?

    /// (Optional)
    /// The ideal number of concurrent streams for a connection. Stream manager will try to create a new connection if
    /// one connection reaches this number. But, if the max connections reaches, manager will reuse connections to create
    /// the acquired steams as much as possible.
    public var idealConcurrentStreamsPerConnection: Int?

    /// (Optional)
    /// Default is no limit, which will use the limit from the server.
    /// The real number of concurrent streams per connection will be controlled by the minimal value of the setting from
    /// other end and the value here.
    public var maxConcurrentStreamsPerConnection: Int?

    public init(clientBootstrap: ClientBootstrap,
                hostName: String,
                port: UInt16,
                proxyOptions: HTTPProxyOptions? = nil,
                proxyEnvSettings: HTTPProxyEnvSettings? = nil,
                socketOptions: SocketOptions = SocketOptions(),
                tlsOptions: TLSConnectionOptions? = nil,
                monitoringOptions: HTTPMonitoringOptions? = nil,
                maxConnections: Int = 2,
                enableStreamManualWindowManagement: Bool = false,
                shutdownCallback: ShutdownCallback? = nil,
                priorKnowledge: Bool = false,
                initialSettings: HTTP2Settings? = nil,
                maxClosedStreams: Int? = nil,
                enableConnectionManualWindowManagement: Bool = false,
                closeConnectionOnServerError: Bool = false,
                connectionPingPeriodMs: Int? = nil,
                connectionPingTimeoutMs: Int? = nil,
                idealConcurrentStreamsPerConnection: Int? = nil,
                maxConcurrentStreamsPerConnection: Int? = nil) {

        self.clientBootstrap = clientBootstrap
        self.hostName = hostName
        self.port = port
        self.proxyOptions = proxyOptions
        self.proxyEnvSettings = proxyEnvSettings
        self.socketOptions = socketOptions
        self.tlsOptions = tlsOptions
        self.monitoringOptions = monitoringOptions
        self.maxConnections = maxConnections
        self.enableStreamManualWindowManagement = enableStreamManualWindowManagement
        self.shutdownCallback = shutdownCallback
        self.priorKnowledge = priorKnowledge
        self.initialSettings = initialSettings
        self.maxClosedStreams = maxClosedStreams
        self.enableConnectionManualWindowManagement = enableConnectionManualWindowManagement
        self.closeConnectionOnServerError = closeConnectionOnServerError
        self.connectionPingPeriodMs = connectionPingPeriodMs
        self.connectionPingTimeoutMs = connectionPingTimeoutMs
        self.idealConcurrentStreamsPerConnection = idealConcurrentStreamsPerConnection
        self.maxConcurrentStreamsPerConnection = maxConcurrentStreamsPerConnection
    }

    typealias RawType = aws_http2_stream_manager_options
    // swiftlint:disable closure_parameter_position
    func withCStruct<Result>(
        shutdownOptions: aws_shutdown_callback_options,
        _ body: (aws_http2_stream_manager_options) -> Result
    ) -> Result {
        return hostName.withByteCursor { hostNameCursor in
            return withOptionalCStructPointer(
                proxyOptions,
                proxyEnvSettings,
                socketOptions,
                monitoringOptions,
                tlsOptions,
                initialSettings) { proxyPointer, proxyEnvSettingsPointer, socketPointer,
                                   monitoringPointer, tlsPointer, http2SettingPointer in

                var cStreamManagerOptions = aws_http2_stream_manager_options()
                cStreamManagerOptions.bootstrap = clientBootstrap.rawValue
                cStreamManagerOptions.host = hostNameCursor
                cStreamManagerOptions.port = port
                cStreamManagerOptions.proxy_options = proxyPointer
                cStreamManagerOptions.proxy_ev_settings = proxyEnvSettingsPointer
                cStreamManagerOptions.socket_options = socketPointer
                cStreamManagerOptions.tls_connection_options = tlsPointer
                cStreamManagerOptions.monitoring_options = monitoringPointer
                cStreamManagerOptions.max_connections = maxConnections
                cStreamManagerOptions.enable_read_back_pressure = enableStreamManualWindowManagement
                cStreamManagerOptions.shutdown_complete_user_data = shutdownOptions.shutdown_callback_user_data
                cStreamManagerOptions.shutdown_complete_callback = shutdownOptions.shutdown_callback_fn

                cStreamManagerOptions.http2_prior_knowledge = priorKnowledge
                cStreamManagerOptions.max_closed_streams = maxClosedStreams ?? 0
                cStreamManagerOptions.conn_manual_window_management = enableConnectionManualWindowManagement
                cStreamManagerOptions.close_connection_on_server_error = closeConnectionOnServerError
                cStreamManagerOptions.connection_ping_period_ms = connectionPingPeriodMs ?? 0
                cStreamManagerOptions.connection_ping_timeout_ms = connectionPingTimeoutMs ?? 0
                cStreamManagerOptions.ideal_concurrent_streams_per_connection = idealConcurrentStreamsPerConnection ?? 0
                cStreamManagerOptions.max_concurrent_streams_per_connection = maxConcurrentStreamsPerConnection ?? 0
                if let http2SettingPointer = http2SettingPointer {
                    return http2SettingPointer.pointee.withUnsafeBufferPointer { pointer in
                        cStreamManagerOptions.initial_settings_array = pointer.baseAddress!
                        cStreamManagerOptions.num_initial_settings = http2SettingPointer.pointee.count
                        return body(cStreamManagerOptions)
                    }
                }
                return body(cStreamManagerOptions)
            }
        }
    }
}
