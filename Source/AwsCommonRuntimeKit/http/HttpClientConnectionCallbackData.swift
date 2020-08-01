//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

class HttpClientConnectionCallbackData {
    var managedConnection: HttpClientConnection?
    let allocator: Allocator
    var connectionOptions: HttpClientConnectionOptions

    init(options: HttpClientConnectionOptions, allocator: Allocator) {
        self.connectionOptions = options
        self.allocator = allocator
    }
}
