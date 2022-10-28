//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp

public class HttpMonitoringOptions: CStruct {
    /// Minimum amount of throughput, in bytes per second, for a connection to be considered healthy
    public var minThroughputBytesPerSecond: UInt64

    /// How long, in seconds, a connection is allowed to be unhealthy before getting shut down.
    /// Must be at least two
    public var allowableThroughputFailureInterval: UInt32

    init(minThroughputBytesPerSecond: UInt64 = 0,
         allowableThroughputFailureInterval: UInt32 = 2) {
        self.minThroughputBytesPerSecond = minThroughputBytesPerSecond
        self.allowableThroughputFailureInterval = allowableThroughputFailureInterval
    }

    typealias RawType = aws_http_connection_monitoring_options
    func withCStruct<Result>(_ body: (aws_http_connection_monitoring_options) -> Result) -> Result {
        var cMonitoringOptions = aws_http_connection_monitoring_options()
        cMonitoringOptions.allowable_throughput_failure_interval_seconds = allowableThroughputFailureInterval
        cMonitoringOptions.minimum_throughput_bytes_per_second = minThroughputBytesPerSecond
        return body(cMonitoringOptions)
    }
}
