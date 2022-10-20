//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

typealias ConnectionContinuation = CheckedContinuation<HttpClientConnection, Error>
typealias ConnectionCallback = (HttpClientConnection) -> Void
class HttpClientConnectionCallbackData {
    let connectionManager: HttpClientConnectionManager
    let continuation: ConnectionContinuation
    let connectionCallback: ConnectionCallback?

    init(continuation: ConnectionContinuation,
         connectionManager: HttpClientConnectionManager,
         connectionCallback: ConnectionCallback? = nil) {
        self.continuation = continuation
        self.connectionManager = connectionManager
        self.connectionCallback = connectionCallback
    }
}
