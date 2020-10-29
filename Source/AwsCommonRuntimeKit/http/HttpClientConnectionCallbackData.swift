//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

struct HttpClientConnectionCallbackData {
    let connectionManager: HttpClientConnectionManager
    let allocator: Allocator
    let onConnectionAcquired: OnConnectionAcquired

    init(onConnectionAcquired: @escaping OnConnectionAcquired,
         connectionManager: HttpClientConnectionManager,
         allocator: Allocator) {
        self.onConnectionAcquired = onConnectionAcquired
        self.connectionManager = connectionManager
        self.allocator = allocator
    }
}
