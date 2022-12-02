//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp
import Collections

typealias OnConnectionAcquired =  (HttpClientConnection?, Int32) -> Void

public class HttpClientConnectionManager {
    let rawValue: OpaquePointer

    public init(options: HttpClientConnectionOptions, allocator: Allocator = defaultAllocator) throws {
        let shutdownCallbackCore = ShutdownCallbackCore(options.shutdownCallback)
        let shutdownOptions = shutdownCallbackCore.getRetainedShutdownOptions()
        guard let rawValue: OpaquePointer = (options.withCPointer(shutdownOptions: shutdownOptions) { managerOptionsPointer in
            return aws_http_connection_manager_new(allocator.rawValue, managerOptionsPointer)
        }) else {
            shutdownCallbackCore.release()
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        self.rawValue = rawValue
    }

    /// Acquires an `HttpClientConnection` asynchronously.
    public func acquireConnection() async throws -> HttpClientConnection {
        return try await withCheckedThrowingContinuation({ (continuation: ConnectionContinuation) in
            HttpClientConnectionManagerCallbackCore(continuation: continuation,
                                                    connectionManager: self).retainedAcquireConnection()
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
