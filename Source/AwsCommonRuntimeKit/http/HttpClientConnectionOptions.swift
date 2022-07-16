//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

public struct HttpClientConnectionOptions {

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
    public let shutDownOptions: ShutDownCallbackOptions?

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
                shutDownOptions: ShutDownCallbackOptions? = nil) {
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
        self.shutDownOptions = shutDownOptions
    }
}
