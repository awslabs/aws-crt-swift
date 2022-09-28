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
         allowableThroughputFailureInterval: Int = 2) {
        self.minThroughputBytesPerSecond = minThroughputBytesPerSecond
        self.allowableThroughputFailureInterval = allowableThroughputFailureInterval

        let options = aws_http_connection_monitoring_options(
            minimum_throughput_bytes_per_second: UInt64(minThroughputBytesPerSecond),
            allowable_throughput_failure_interval_seconds: UInt32(allowableThroughputFailureInterval),
            statistics_observer_fn: nil,
            statistics_observer_user_data: nil
        )
        rawValue = fromPointer(ptr: options)
    }

    deinit {
        rawValue.deinitializeAndDeallocate()
    }
}
