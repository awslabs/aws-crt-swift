//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCHttp
import Collections

typealias OnConnectionAcquired = (HttpClientConnection?, Int32) -> Void

public class HttpClientConnectionManager {

    var queue: Deque<HttpClientConnection> = Deque<HttpClientConnection>()
    let manager: OpaquePointer
    let allocator: Allocator
    let options: HttpClientConnectionOptions

    public init(options: HttpClientConnectionOptions, allocator: Allocator = defaultAllocator) {
        self.options = options
        self.allocator = allocator
        let shutDownPtr: UnsafeMutablePointer<ShutDownCallbackOptions>? = fromOptionalPointer(ptr: options.shutDownOptions)
        var mgrOptions = aws_http_connection_manager_options(bootstrap: options.clientBootstrap.rawValue,
                initial_window_size: options.initialWindowSize,
                socket_options: options.socketOptions.rawValue,
                tls_connection_options: options.tlsOptions?.rawValue,
                http2_prior_knowledge: false,
                monitoring_options: options.monitoringOptions?.rawValue,
                host: options.hostName.awsByteCursor,
                port: options.port,
                initial_settings_array: nil,
                num_initial_settings: 0,
                max_closed_streams: 0,
                http2_conn_manual_window_management: false,
                proxy_options: options.proxyOptions?.rawValue,
                proxy_ev_settings: options.proxyEnvSettings?.rawValue,
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

        self.manager = aws_http_connection_manager_new(allocator.rawValue, &mgrOptions)
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
                allocator: allocator) { [weak self] connection in
            self?.queue.append(connection)
        }
        let cbData: UnsafeMutablePointer<HttpClientConnectionCallbackData> = fromPointer(ptr: callbackData)

        aws_http_connection_manager_acquire_connection(manager, { (connection, errorCode, userData) in
            guard let userData = userData else {
                return
            }
            let callbackData = userData.assumingMemoryBound(to: HttpClientConnectionCallbackData.self)
            defer {
                callbackData.deinitializeAndDeallocate()
            }
            guard let connection = connection else {
                let error = AWSError(errorCode: errorCode)
                callbackData.pointee.continuation.resume(throwing: CRTError.crtError(error))
                return
            }
            let httpConnection = HttpClientConnection(manager: callbackData.pointee.connectionManager,
                    connection: connection)
            if let connectionCallback = callbackData.pointee.connectionCallback {
                connectionCallback(httpConnection)
            }

            callbackData.pointee.continuation.resume(returning: httpConnection)
        },
                cbData)
    }

    public func closePendingConnections() {
        while !queue.isEmpty {
            if let clientConnection = queue.popFirst() {
                clientConnection.close()
            }
        }
    }

    ///Releases this HttpClientConnection back into the Connection Pool, and allows another Request to acquire
    ///this connection.
    /// - Parameters:
    ///     - connection:  `HttpClientConnection` to release

    public func releaseConnection(connection: HttpClientConnection) {
        aws_http_connection_manager_release_connection(manager, connection.rawValue)
    }

    deinit {
        aws_http_connection_manager_release(manager)
    }
}
