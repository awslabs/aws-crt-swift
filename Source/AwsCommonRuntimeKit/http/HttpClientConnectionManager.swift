//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp
import Collections

typealias OnConnectionAcquired =  (HttpClientConnection?, Int32) -> Void

public class HttpClientConnectionManager {
    let manager: OpaquePointer
    let allocator: Allocator
    let options: HttpClientConnectionOptions

    public init(options: HttpClientConnectionOptions, allocator: Allocator = defaultAllocator) throws {
        self.options = options
        self.allocator = allocator
        let cShutdownOptions = ShutDownCallbackOptions(options.shutdownCallback)?.getCShutdownOptions()
        guard let manager: OpaquePointer = (options.hostName.withByteCursor { hostNameCursor in
            var mgrOptions = aws_http_connection_manager_options(bootstrap: options.clientBootstrap.rawValue,
                                                                 initial_window_size: options.initialWindowSize,
                                                                 socket_options: options.socketOptions.rawValue,
                                                                 tls_connection_options: options.tlsOptions?.rawValue,
                                                                 http2_prior_knowledge: false,
                                                                 monitoring_options: options.monitoringOptions?.rawValue,
                                                                 host: hostNameCursor,
                                                                 port: options.port,
                                                                 initial_settings_array: nil,
                                                                 num_initial_settings: 0,
                                                                 max_closed_streams: 0,
                                                                 http2_conn_manual_window_management: false,
                                                                 proxy_options: options.proxyOptions?.rawValue,
                                                                 proxy_ev_settings: options.proxyEnvSettings?.rawValue,
                                                                 max_connections: options.maxConnections,
                                                                 shutdown_complete_user_data: cShutdownOptions?.shutdown_callback_user_data,
                                                                 shutdown_complete_callback: cShutdownOptions?.shutdown_callback_fn,
                                                                 enable_read_back_pressure: options.enableManualWindowManagement,
                                                                 max_connection_idle_in_milliseconds: options.maxConnectionIdleMs)
            return aws_http_connection_manager_new(allocator.rawValue, &mgrOptions)
        }) else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        self.manager = manager
    }

    /// Acquires an `HttpClientConnection` asynchronously.
    public func acquireConnection() async throws -> HttpClientConnection {
        return try await withCheckedThrowingContinuation({ (continuation: ConnectionContinuation) in
            acquireConnection(continuation: continuation)
        })
    }

    private func acquireConnection(continuation: ConnectionContinuation) {
        let callbackData = HttpClientConnectionCallbackData(continuation: continuation,
                                                            connectionManager: self,
                                                            allocator: allocator)

        aws_http_connection_manager_acquire_connection(manager, { (connection, errorCode, userData) in
            guard let userData = userData else {
                return
            }
            let callbackData = Unmanaged<HttpClientConnectionCallbackData>.fromOpaque(userData).takeRetainedValue()
            guard let connection = connection else {
                callbackData.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(errorCode: errorCode)))
                return
            }
            let httpConnection = HttpClientConnection(manager: callbackData.connectionManager,
                                                      connection: connection)
            if let connectionCallback = callbackData.connectionCallback {
                connectionCallback(httpConnection)
            }
            callbackData.continuation.resume(returning: httpConnection)
        },
        Unmanaged.passRetained(callbackData).toOpaque())
    }

    /// Releases this HttpClientConnection back into the Connection Pool, and allows another Request to acquire
    /// this connection.
    /// - Parameters:
    ///     - connection:  `HttpClientConnection` to release
    public func releaseConnection(connection: HttpClientConnection) throws {
        if aws_http_connection_manager_release_connection(manager, connection.rawValue) != AWS_OP_SUCCESS {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
    }

    deinit {
        aws_http_connection_manager_release(manager)
    }
}
