//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

public struct HTTPClientConnectionManagerMetrics {
    /// The number of additional concurrent requests that can be supported by the HTTP manager without needing to
    /// establish additional connections to the target server.
    ///
    /// For connection manager, it equals to connections that's idle.
    /// For stream manager, it equals to the number of streams that are possible to be made without creating new
    /// connection, although the implementation can create new connection without fully filling it.
    public var availableConcurrency: Int
    /// The number of requests that are awaiting concurrency to be made available from the HTTP manager.
    public var pendingConcurrencyAcquires: Int
    /// The number of connections (http/1.1) or streams (for h2 via. stream manager) currently vended to user.
    public var leasedConcurrency: Int

    public init(
        availableConcurrency: Int = 0,
        pendingConcurrencyAcquires: Int = 0,
        leasedConcurrency: Int = 0
    ) {
        self.availableConcurrency = availableConcurrency
        self.pendingConcurrencyAcquires = pendingConcurrencyAcquires
        self.leasedConcurrency = leasedConcurrency
    }
}
