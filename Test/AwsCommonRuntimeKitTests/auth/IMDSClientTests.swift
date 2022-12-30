//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
import AwsCAuth
import Foundation
@testable import AwsCommonRuntimeKit

//TODO: write some tests
class IMDSClientTest: XCBaseTestCase {


    func isEnvironmentSetup() throws {
        guard ProcessInfo.processInfo.environment["AWS_TEST_IMDS"] != nil else {
            try skipTest(message: "Skipping because AWS_TEST_IMDS environment var is not set.")
            return
        }
    }
    //test
    func testGetAmiId() async throws {
        try isEnvironmentSetup()

        let elg = try EventLoopGroup(threadCount: 0, allocator: allocator)
        let hostResolver = try HostResolver(eventLoopGroup: elg,
                maxHosts: 8,
                maxTTL: 30,
                allocator: allocator)
        let bootstrap = try ClientBootstrap(eventLoopGroup: elg,
                hostResolver: hostResolver,
                allocator: allocator)
        let retryStrategy = try RetryStrategy(eventLoopGroup: elg)
        let client = try IMDSClient(bootstrap: bootstrap, retryStrategy: retryStrategy, allocator: allocator)
        let id = try await client.getAmiId()
        print(id)
        XCTAssertFalse(id.isEmpty)
    }
}
