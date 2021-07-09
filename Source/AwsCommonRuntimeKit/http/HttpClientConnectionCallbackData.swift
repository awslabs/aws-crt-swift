//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

typealias ConnectionContinuation = CheckedContinuation<HttpClientConnection, Error>
struct HttpClientConnectionCallbackData {
    let connectionManager: HttpClientConnectionManager
    let allocator: Allocator
    let continuation: ConnectionContinuation

    init(continuation: ConnectionContinuation,
         connectionManager: HttpClientConnectionManager,
         allocator: Allocator) {
        self.continuation = continuation
        self.connectionManager = connectionManager
        self.allocator = allocator
    }
}
