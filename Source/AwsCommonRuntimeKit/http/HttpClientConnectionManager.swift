//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import Foundation

typealias OnConnectionSetup =  (HttpClientConnection?, Int32) -> Void
typealias OnConnectionShutdown = (HttpClientConnection?, Int32) -> Void

public class HttpClientConnectionManager {

    var queue: Queue<Future<HttpClientConnection>> = Queue<Future<HttpClientConnection>>()

    let options: HttpClientConnectionOptions

    public init(options: HttpClientConnectionOptions) {
        self.options = options
    }

    public static func create(options: HttpClientConnectionOptions) -> HttpClientConnectionManager {
        return HttpClientConnectionManager(options: options)
    }

    public func acquireConnection() -> Future<HttpClientConnection> {
        let future = Future<HttpClientConnection>()
        let onConnectionSetup: OnConnectionSetup = { connection, errorCode in
            guard let future = self.queue.dequeue() else {
                //this should never happen
                return
            }
            guard let connection = connection else {
                let error = HttpConnectionError(errorCode: Int(errorCode))
                future.complete(.failure(error))
                return
            }

            future.complete(.success(connection))
        }

        let onConnectionShutDown: OnConnectionShutdown = { connection, errorCode in
            guard let future = self.queue.dequeue() else {
                //this should never happen
                return
            }
            let error = HttpConnectionError(errorCode: Int(errorCode))
            future.complete(.failure(error))
        }

        HttpClientConnection.createConnection(options: self.options,
                                              onConnectionSetup: onConnectionSetup,
                                              onConnectionShutdown: onConnectionShutDown)
        queue.enqueue(future)
        return future
    }

    public func closePendingConnections() {
        while !queue.isEmpty {
            if let future = queue.dequeue() {
                future.complete(.failure(HttpConnectionError(errorCode: -1)))
            }
        }
    }
}
