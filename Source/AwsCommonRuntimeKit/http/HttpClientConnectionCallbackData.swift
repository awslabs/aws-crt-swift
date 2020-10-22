//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

class HttpClientConnectionCallbackData {
    var managedConnection: HttpClientConnection?
    let allocator: Allocator
    var connectionOptions: HttpClientConnectionOptions
    let onConnectionSetup: OnConnectionSetup
    let onConnectionShutdown: OnConnectionShutdown

    init(options: HttpClientConnectionOptions,
         onConnectionSetup: @escaping OnConnectionSetup,
         onConnectionShutdown: @escaping OnConnectionShutdown,
         allocator: Allocator) {
        self.connectionOptions = options
        self.onConnectionSetup = onConnectionSetup
        self.onConnectionShutdown = onConnectionShutdown
        self.allocator = allocator
    }
}
