//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
@testable import AwsCommonRuntimeKit

class HTTPMonitoringOptionsTests: XCBaseTestCase {

    func testCreateHttpMonitoringOptions() throws {
        let monitoringOptions = HTTPMonitoringOptions(minThroughputBytesPerSecond: 10, allowableThroughputFailureInterval: 100)
        monitoringOptions.withCStruct { cMonitoringOptions in
            XCTAssertEqual(cMonitoringOptions.minimum_throughput_bytes_per_second, 10)
            XCTAssertEqual(cMonitoringOptions.allowable_throughput_failure_interval_seconds, 100)
        }
    }
}
