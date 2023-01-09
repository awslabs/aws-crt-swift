//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCHttp

public struct HTTPClientConnectionOptions: CStructWithShutdownOptions {

    /// The client bootstrap instance to use to create the pool's connections
    public var clientBootstrap: ClientBootstrap
    /// The host name to use for connections in the connection pool
    public var hostName: String
    /// The IO channel window size to use for connections in the connection pool
    public var initialWindowSize: Int
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

    /// If set to true, then the TCP read back pressure mechanism will be enabled. You should
    /// only use this if you're allowing http response body data to escape the callbacks. E.g. you're
    /// putting the data into a queue for another thread to process and need to make sure the memory
    /// usage is bounded (e.g. reactive streams).
    /// If this is enabled, you must call HTTPStream.updateWindow() for every
    /// byte read from the OnIncomingBody callback.
    /// Will be true if manual window management is used, but defaults to false
    public var enableManualWindowManagement: Bool

    /// Max connections the manager can contain
    public var maxConnections: Int

    /// Add a shut down callback using these options
    public var shutdownCallback: ShutdownCallback?

    /// If set to a non-zero value, then connections that stay in the pool longer than the specified
    /// timeout will be closed automatically.
    public var maxConnectionIdleMs: UInt64

    public var monitoringOptions: HTTPMonitoringOptions?

    /// (Optional) HTTP/2 specific configuration
    /// Specify whether you have prior knowledge that cleartext (HTTP) connections are HTTP/2 (RFC-7540 3.4).
    /// If false, then cleartext connections are treated as HTTP/1.1.
    /// It is illegal to set this true when secure connections are being used.
    /// Note that upgrading from HTTP/1.1 to HTTP/2 is not supported (RFC-7540 3.2).
    public var http2PriorKnowledge: Bool

    /// (Optional) HTTP/2 specific configuration
    /// The data of settings to change for initial settings.
    /// Note: each setting has its boundary.
    public var http2InitialSettings: HTTP2Settings?

    /// (Optional) HTTP/2 specific configuration
    /// The max number of recently-closed streams to remember.
    /// Set it to nil to use the default setting
    ///
    /// If the connection receives a frame for a closed stream,
    /// the frame will be ignored or cause a connection error,
    /// depending on the frame type and how the stream was closed.
    /// Remembering more streams reduces the chances that a late frame causes
    /// a connection error, but costs some memory.
    public var http2MaxClosedStreams: Int?

    /// (Optional) HTTP/2 specific configuration
    /// Set to true to manually manage the flow-control window of whole HTTP/2 connection.
    ///
    /// If false, the connection will maintain its flow-control windows such that
    /// no back-pressure is applied and data arrives as fast as possible.
    ///
    /// If true, the flow-control window of the whole connection will shrink as body data
    /// is received (headers, padding, and other metadata do not affect the window) for every streams
    /// created on this connection.
    /// The initial connection flow-control window is 65,535.
    /// Once the connection's flow-control window reaches to 0, all the streams on the connection stop receiving any
    /// further data.
    /// The user must call aws_http2_connection_update_window() to increment the connection's // TODO: update
    /// window and keep data flowing.
    /// Note: the padding of data frame counts to the flow-control window.
    /// But, the client will always automatically update the window for padding even for manual window update.
    public var http2EnableManualWindowManagement: Bool

    public init(clientBootstrap: ClientBootstrap,
                hostName: String,
                initialWindowSize: Int = Int.max,
                port: UInt16,
                proxyOptions: HTTPProxyOptions? = nil,
                proxyEnvSettings: HTTPProxyEnvSettings? = nil,
                socketOptions: SocketOptions = SocketOptions(),
                tlsOptions: TLSConnectionOptions? = nil,
                monitoringOptions: HTTPMonitoringOptions? = nil,
                maxConnections: Int = 2,
                enableManualWindowManagement: Bool = false,
                maxConnectionIdleMs: UInt64 = 0,
                shutdownCallback: ShutdownCallback? = nil,
                http2PriorKnowledge: Bool = false,
                http2InitialSettings: HTTP2Settings? = nil,
                http2MaxClosedStreams: Int? = nil,
                http2EnableManualWindowManagement: Bool = false) {

        self.clientBootstrap = clientBootstrap
        self.hostName = hostName
        self.initialWindowSize = initialWindowSize
        self.port = port
        self.proxyOptions = proxyOptions
        self.proxyEnvSettings = proxyEnvSettings
        self.socketOptions = socketOptions
        self.tlsOptions = tlsOptions
        self.monitoringOptions = monitoringOptions
        self.maxConnections = maxConnections
        self.enableManualWindowManagement = enableManualWindowManagement
        self.maxConnectionIdleMs = maxConnectionIdleMs
        self.shutdownCallback = shutdownCallback
        self.http2PriorKnowledge = http2PriorKnowledge
        self.http2InitialSettings = http2InitialSettings
        self.http2MaxClosedStreams = http2MaxClosedStreams
        self.http2EnableManualWindowManagement = http2EnableManualWindowManagement
    }

    typealias RawType = aws_http_connection_manager_options
    // swiftlint:disable closure_parameter_position
    func withCStruct<Result>(
        shutdownOptions: aws_shutdown_callback_options,
        _ body: (aws_http_connection_manager_options) -> Result
    ) -> Result {
        return hostName.withByteCursor { hostNameCursor in
            return withOptionalCStructPointer(
                proxyOptions,
                proxyEnvSettings,
                socketOptions,
                monitoringOptions,
                tlsOptions,
                http2InitialSettings) { proxyPointer, proxyEnvSettingsPointer, socketPointer,
                                        monitoringPointer, tlsPointer, http2SettingPointer in

                var cManagerOptions = aws_http_connection_manager_options()
                cManagerOptions.bootstrap = clientBootstrap.rawValue
                cManagerOptions.initial_window_size = initialWindowSize
                cManagerOptions.socket_options = socketPointer
                cManagerOptions.tls_connection_options = tlsPointer
                cManagerOptions.monitoring_options = monitoringPointer
                cManagerOptions.host = hostNameCursor
                cManagerOptions.port = port
                cManagerOptions.proxy_options = proxyPointer
                cManagerOptions.shutdown_complete_user_data = shutdownOptions.shutdown_callback_user_data
                cManagerOptions.shutdown_complete_callback = shutdownOptions.shutdown_callback_fn
                cManagerOptions.proxy_ev_settings = proxyEnvSettingsPointer
                cManagerOptions.max_connections = maxConnections
                cManagerOptions.enable_read_back_pressure = enableManualWindowManagement
                cManagerOptions.max_connection_idle_in_milliseconds = maxConnectionIdleMs
                cManagerOptions.http2_prior_knowledge = http2PriorKnowledge
                cManagerOptions.max_closed_streams = http2MaxClosedStreams ?? 0
                cManagerOptions.http2_conn_manual_window_management = http2EnableManualWindowManagement
                if let http2SettingPointer = http2SettingPointer {
                    return http2SettingPointer.pointee.withUnsafeBufferPointer { pointer in
                        cManagerOptions.initial_settings_array = pointer.baseAddress!
                        cManagerOptions.num_initial_settings = http2SettingPointer.pointee.count
                        return body(cManagerOptions)
                    }
                }
                return body(cManagerOptions)
            }
        }
    }
}
