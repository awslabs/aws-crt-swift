//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp

public class HttpMonitoringOptions {
    /// Minimum amount of throughput, in bytes per second, for a connection to be considered healthy
    public let minThroughputBytesPerSecond: Int

    /// How long, in seconds, a connection is allowed to be unhealthy before getting shut down.
    /// Must be at least two
    public let allowableThroughputFailureInterval: Int

    let rawValue: UnsafeMutablePointer<aws_http_connection_monitoring_options>

    init(minThroughputBytesPerSecond: Int = 0,
         allowableThroughputFailureInterval: Int = 2,
         allocator: Allocator = defaultAllocator) {
        self.minThroughputBytesPerSecond = minThroughputBytesPerSecond
        self.allowableThroughputFailureInterval = allowableThroughputFailureInterval

        self.rawValue = allocator.allocate(capacity: 1)
        rawValue.pointee.minimum_throughput_bytes_per_second = UInt64(minThroughputBytesPerSecond)
        rawValue.pointee.allowable_throughput_failure_interval_seconds = UInt32(allowableThroughputFailureInterval)
    }

    deinit {
        rawValue.deinitializeAndDeallocate()
    }
}
