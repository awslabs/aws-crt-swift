//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

typealias ConnectionContinuation = CheckedContinuation<HttpClientConnection, Error>
typealias ConnectionCallback = (HttpClientConnection) -> Void
struct HttpClientConnectionCallbackData {
    let connectionManager: HttpClientConnectionManager
    let allocator: Allocator
    let continuation: ConnectionContinuation
    let connectionCallback: ConnectionCallback?

    init(continuation: ConnectionContinuation,
         connectionManager: HttpClientConnectionManager,
         allocator: Allocator,
         connectionCallback: ConnectionCallback? = nil) {
        self.continuation = continuation
        self.connectionManager = connectionManager
        self.allocator = allocator
        self.connectionCallback = connectionCallback
    }
}
