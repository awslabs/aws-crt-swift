//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp

public class HttpClientConnectionOptions: CStructWithShutdownOptions {
    typealias cStructType = aws_http_connection_manager_options
    /// The client bootstrap instance to use to create the pool's connections
    public let clientBootstrap: ClientBootstrap
    /// The host name to use for connections in the connection pool
    public let hostName: String
    /// The IO channel window size to use for connections in the connection pool
    public let initialWindowSize: Int
    /// The port to connect to for connections in the connection pool
    public let port: UInt16
    /// The proxy options for connections in the connection pool
    public let proxyOptions: HttpProxyOptions?
    /// Configuration for using proxy from environment variable. Only works when proxyOptions is not set.
    public let proxyEnvSettings: ProxyEnvSettings?
    /// The socket options to use for connections in the connection pool
    public var socketOptions: SocketOptions
    /// The tls options to use for connections in the connection pool
    public let tlsOptions: TlsConnectionOptions?
    /**
     If set to true, then the TCP read back pressure mechanism will be enabled. You should
     only use this if you're allowing http response body data to escape the callbacks. E.g. you're
     putting the data into a queue for another thread to process and need to make sure the memory
     usage is bounded (e.g. reactive streams).
     If this is enabled, you must call HttpStream.updateWindow() for every
     byte read from the OnIncomingBody callback.
     Will be true if manual window management is used, but defaults to false
     */
    public let enableManualWindowManagement: Bool

    /// Max connections the manager can contain
    public let maxConnections: Int

    /// Add a shut down callback using these options
    public let shutdownCallback: ShutdownCallback?

    /// If set to a non-zero value, then connections that stay in the pool longer than the specified
    /// timeout will be closed automatically.
    public let maxConnectionIdleMs: UInt64

    public let monitoringOptions: HttpMonitoringOptions?

    public init(clientBootstrap bootstrap: ClientBootstrap,
                hostName: String,
                initialWindowSize: Int = Int.max,
                port: UInt16,
                proxyOptions: HttpProxyOptions?,
                proxyEnvSettings: ProxyEnvSettings? = nil,
                socketOptions: SocketOptions,
                tlsOptions: TlsConnectionOptions?,
                monitoringOptions: HttpMonitoringOptions?,
                maxConnections: Int = 2,
                enableManualWindowManagement: Bool = false,
                maxConnectionIdleMs: UInt64 = 0,
                shutdownCallback: ShutdownCallback? = nil) {

        self.clientBootstrap = bootstrap
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
    }

    func withCStruct<Result>(shutdownOptions: aws_shutdown_callback_options, _ body: (aws_http_connection_manager_options) -> Result
    ) -> Result {
            return hostName.withByteCursor { hostNameCursor in
                return withOptionalCStructPointer(to: proxyOptions) { proxyOptionsPointer in
                    var cManagerOptions = aws_http_connection_manager_options()
                    cManagerOptions.bootstrap = clientBootstrap.rawValue
                    cManagerOptions.initial_window_size = initialWindowSize
                    cManagerOptions.socket_options = UnsafePointer(socketOptions.rawValue) //TODO: fix
                    cManagerOptions.tls_connection_options = UnsafePointer(tlsOptions?.rawValue)
                    cManagerOptions.http2_prior_knowledge = false
                    cManagerOptions.monitoring_options = UnsafePointer(monitoringOptions?.rawValue)
                    cManagerOptions.host = hostNameCursor
                    cManagerOptions.port = port
                    cManagerOptions.initial_settings_array = nil
                    cManagerOptions.num_initial_settings = 0
                    cManagerOptions.max_closed_streams = 0
                    cManagerOptions.http2_conn_manual_window_management = false
                    cManagerOptions.proxy_options = proxyOptionsPointer
                    cManagerOptions.shutdown_complete_user_data = shutdownOptions.shutdown_callback_user_data
                    cManagerOptions.shutdown_complete_callback = shutdownOptions.shutdown_callback_fn
                    cManagerOptions.proxy_ev_settings = UnsafePointer(proxyEnvSettings?.getRawValue())
                    cManagerOptions.max_connections = maxConnections
                    cManagerOptions.enable_read_back_pressure = enableManualWindowManagement
                    cManagerOptions.max_connection_idle_in_milliseconds = maxConnectionIdleMs
                    return body(cManagerOptions)
                }
        }
    }
}
