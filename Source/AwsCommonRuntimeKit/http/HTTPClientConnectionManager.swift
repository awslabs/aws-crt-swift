//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp

typealias OnConnectionAcquired = (HTTPClientConnection?, Int32) -> Void

public class HTTPClientConnectionManager: @unchecked Sendable {
  let rawValue: OpaquePointer

  public init(options: HTTPClientConnectionOptions) throws {
    let shutdownCallbackCore = ShutdownCallbackCore(options.shutdownCallback)
    let shutdownOptions = shutdownCallbackCore.getRetainedShutdownOptions()
    guard
      let rawValue: OpaquePointer =
        (options.withCPointer(shutdownOptions: shutdownOptions) { managerOptionsPointer in
          return aws_http_connection_manager_new(allocator.rawValue, managerOptionsPointer)
        })
    else {
      shutdownCallbackCore.release()
      throw CommonRunTimeError.crtError(.makeFromLastError())
    }
    self.rawValue = rawValue
  }

  /// Acquires an `HTTPClientConnection` asynchronously.
  public func acquireConnection() async throws -> HTTPClientConnection {
    return try await withCheckedThrowingContinuation({ (continuation: ConnectionContinuation) in
      HTTPClientConnectionManagerCallbackCore.acquireConnection(
        continuation: continuation,
        connectionManager: self)
    })
  }

  /// Releases this HTTPClientConnection back into the Connection Pool, and allows another Request to acquire
  /// this connection.
  /// - Parameters:
  ///     - connection:  `HTTPClientConnection` to release
  func releaseConnection(connection: HTTPClientConnection) throws {
    if aws_http_connection_manager_release_connection(rawValue, connection.rawValue)
      != AWS_OP_SUCCESS
    {
      throw CommonRunTimeError.crtError(.makeFromLastError())
    }
  }

  /// Fetch the current manager metrics from connection manager.
  public func fetchMetrics() -> HTTPClientConnectionManagerMetrics {
    var cManagerMetrics = aws_http_manager_metrics()
    aws_http_connection_manager_fetch_metrics(rawValue, &cManagerMetrics)
    return HTTPClientConnectionManagerMetrics(
      availableConcurrency: cManagerMetrics.available_concurrency,
      pendingConcurrencyAcquires: cManagerMetrics.pending_concurrency_acquires,
      leasedConcurrency: cManagerMetrics.leased_concurrency
    )
  }

  deinit {
    aws_http_connection_manager_release(rawValue)
  }
}
