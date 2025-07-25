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
  public var port: UInt32
  /// The proxy options for connections in the connection pool
  public var proxyOptions: HTTPProxyOptions?
  /// Configuration for using proxy from environment variable. Only works when proxyOptions is not set.
  public var proxyEnvSettings: HTTPProxyEnvSettings?
  /// The socket options to use for connections in the connection pool
  public var socketOptions: SocketOptions
  /// The TLS options for creating secure (HTTPS) connections.
  /// Leave as NULL to create cleartext (HTTP) connections.
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

  public init(
    clientBootstrap: ClientBootstrap,
    hostName: String,
    initialWindowSize: Int = Int.max,
    port: UInt32,
    proxyOptions: HTTPProxyOptions? = nil,
    proxyEnvSettings: HTTPProxyEnvSettings? = nil,
    socketOptions: SocketOptions = SocketOptions(),
    tlsOptions: TLSConnectionOptions? = nil,
    monitoringOptions: HTTPMonitoringOptions? = nil,
    maxConnections: Int = 2,
    enableManualWindowManagement: Bool = false,
    maxConnectionIdleMs: UInt64 = 0,
    shutdownCallback: ShutdownCallback? = nil
  ) {

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
  }

  typealias RawType = aws_http_connection_manager_options
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
        tlsOptions
      ) { proxyPointer, proxyEnvSettingsPointer, socketPointer, monitoringPointer, tlsPointer in

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
        return body(cManagerOptions)
      }
    }
  }
}
