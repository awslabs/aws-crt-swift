//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
import AwsCCommon
@testable import AwsCommonRuntimeKit

class SocketOptionsTests: CrtXCBaseTestCase {

    func testCreateSocketOptions() throws {
        let socketOptions = SocketOptions(socketType: SocketType.datagram, allocator: allocator)
        XCTAssertNotNil(socketOptions)
    }

    func testCanModifySocketOptions() throws {
        let socketOptions = SocketOptions(socketType: SocketType.datagram, allocator: allocator)
        XCTAssertNotNil(socketOptions)

        socketOptions.connectTimeoutMs = 1_000
        XCTAssertEqual(socketOptions.connectTimeoutMs, 1_000)

        socketOptions.keepAlive = true
        XCTAssertTrue(socketOptions.keepAlive)

        socketOptions.keepaliveIntervalSec = 10
        XCTAssertEqual(socketOptions.keepaliveIntervalSec, 10)

        socketOptions.keepaliveMaxFailedProbes = 10
        XCTAssertEqual(socketOptions.keepaliveMaxFailedProbes, 10)

        socketOptions.keepaliveTimeoutSec = 10
        XCTAssertEqual(socketOptions.keepaliveTimeoutSec, 10)

        socketOptions.socketDomain = SocketDomain.ipv6
        XCTAssertEqual(socketOptions.socketDomain, SocketDomain.ipv6)

        socketOptions.socketType = SocketType.stream
        XCTAssertEqual(socketOptions.socketType, SocketType.stream)
    }
}
