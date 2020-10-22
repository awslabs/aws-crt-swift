//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

typealias OnConnectionSetup =  (HttpClientConnection?, Int32) -> Void
typealias OnConnectionShutdown = (HttpClientConnection?, Int32) -> Void

public class HttpClientConnectionManager {
    
    
    public static func create(options: HttpClientConnectionOptions) -> Future<HttpClientConnection> {
        let future = Future<HttpClientConnection>()
        
        let onConnectionSetup: OnConnectionSetup = { connection, errorCode in
            guard let connection = connection else {
                let error = HttpConnectionError(rawValue: errorCode)
                future.complete(.failure(error))
                return
            }
            future.complete(.success(connection))
        }
        
        let onConnectionShutDown: OnConnectionShutdown = { connection, errorCode in
            let error = HttpConnectionError(rawValue: errorCode)
            future.complete(.failure(error))
        }
        
        HttpClientConnection.createConnection(options: options,
                                              onConnectionSetup: onConnectionSetup,
                                              onConnectionShutdown: onConnectionShutDown)
        return future
    }
    
}
