//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp
import Collections

typealias OnConnectionAcquired =  (HttpClientConnection?, Int32) -> Void

public class HttpClientConnectionManager {
    let rawValue: OpaquePointer
    let options: HttpClientConnectionOptions

    public init(options: HttpClientConnectionOptions, allocator: Allocator = defaultAllocator) throws {
        self.options = options
        // Todo: fix shutdown options
        let shutDownPtr: UnsafeMutablePointer<ShutDownCallbackOptions>? = fromOptionalPointer(ptr: options.shutDownOptions)

        guard let rawValue: OpaquePointer = (options.hostName.withByteCursor { hostNameCursor in
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
                                                                 proxy_options: options.proxyOptions?.getRawValue(),
                                                                 proxy_ev_settings: options.proxyEnvSettings?.getRawValue(),
                                                                 max_connections: options.maxConnections,
                                                                 shutdown_complete_user_data: shutDownPtr,
                                                                 shutdown_complete_callback: { (userData) in
                                                                    guard let userData = userData else {
                                                                        return
                                                                    }
                                                                    let callbackOptions = userData.assumingMemoryBound(
                                                                        to: ShutDownCallbackOptions.self)
                                                                    defer {
                                                                        callbackOptions.deinitializeAndDeallocate()
                                                                    }
                                                                    callbackOptions.pointee.shutDownCallback(
                                                                        callbackOptions.pointee.semaphore)
                                                                 },
                                                                 enable_read_back_pressure: options.enableManualWindowManagement,
                                                                 max_connection_idle_in_milliseconds: options.maxConnectionIdleMs)
            return aws_http_connection_manager_new(allocator.rawValue, &mgrOptions)
        }) else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        self.rawValue = rawValue
    }

    /// Acquires an `HttpClientConnection` asynchronously.
    public func acquireConnection() async throws -> HttpClientConnection {
        return try await withCheckedThrowingContinuation({ (continuation: ConnectionContinuation) in
            let connectionManagerCallbackCore = HttpClientConnectionManagerCallbackCore(continuation: continuation,
                                                                        connectionManager: self)
            connectionManagerCallbackCore.retainedAcquireConnection()
        })
    }

    /// Releases this HttpClientConnection back into the Connection Pool, and allows another Request to acquire
    /// this connection.
    /// - Parameters:
    ///     - connection:  `HttpClientConnection` to release
    func releaseConnection(connection: HttpClientConnection) throws {
        if aws_http_connection_manager_release_connection(rawValue, connection.rawValue) != AWS_OP_SUCCESS {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
    }

    deinit {
        aws_http_connection_manager_release(rawValue)
    }
}
