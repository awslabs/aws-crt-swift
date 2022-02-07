//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp

typealias OnConnectionAcquired =  (HttpClientConnection?, Int32) -> Void

public class HttpClientConnectionManager {

    var queue: Queue<Future<HttpClientConnection>> = Queue<Future<HttpClientConnection>>()
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
                                                             monitoring_options: options.monitoringOptions?.rawValue,
                                                             host: options.hostName.awsByteCursor,
                                                             port: options.port,
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
                                                                defer {callbackOptions.deinitializeAndDeallocate()}
                                                                callbackOptions.pointee.shutDownCallback(
                                                                    callbackOptions.pointee.semaphore)
                                                            },
                                                             enable_read_back_pressure: options.enableManualWindowManagement,
                                                             max_connection_idle_in_milliseconds: options.maxConnectionIdleMs)

        self.manager = aws_http_connection_manager_new(allocator.rawValue, &mgrOptions)
    }

    /// Acquires an `HttpClientConnection` asynchronously.
    public func acquireConnection() -> Future<HttpClientConnection> {
        let future = Future<HttpClientConnection>()
        let onConnectionAcquired: OnConnectionAcquired = { connection, errorCode in
            guard let future = self.queue.dequeue() else {
                //this should never happen
                return
            }
            guard let connection = connection else {
                let error = AWSError(errorCode: errorCode)
                future.fail(CRTError.crtError(error))
                return
            }

            future.fulfill(connection)
        }
        let callbackData = HttpClientConnectionCallbackData(onConnectionAcquired: onConnectionAcquired,
                                                            connectionManager: self,
                                                            allocator: allocator)
        let cbData: UnsafeMutablePointer<HttpClientConnectionCallbackData> = fromPointer(ptr: callbackData)

        aws_http_connection_manager_acquire_connection(manager, { (connection, errorCode, userData) in
            guard let userData = userData else {
                return
            }
            let callbackData = userData.assumingMemoryBound(to: HttpClientConnectionCallbackData.self)
            defer {callbackData.deinitializeAndDeallocate()}
            guard let connection = connection else {
                callbackData.pointee.onConnectionAcquired(nil, errorCode)
                return
            }
            let httpConnection = HttpClientConnection(manager: callbackData.pointee.connectionManager,
                                                      connection: connection)
            callbackData.pointee.onConnectionAcquired(httpConnection, errorCode)
        },
        cbData)
        queue.enqueue(future)
        return future
    }

    public func closePendingConnections() {
        while !queue.isEmpty {
            if let future = queue.dequeue() {
                let error = AWSError(errorCode: -1)
                future.fail(CRTError.crtError(error))
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
