//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

typealias ConnectionContinuation = CheckedContinuation<HttpClientConnection, Error>
class HttpClientConnectionCallbackDataCore {
    let connectionManager: HttpClientConnectionManager
    let continuation: ConnectionContinuation

    init(continuation: ConnectionContinuation,
         connectionManager: HttpClientConnectionManager) {
        self.continuation = continuation
        self.connectionManager = connectionManager
    }
}
