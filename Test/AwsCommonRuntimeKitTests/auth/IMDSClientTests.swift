//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit

class IMDSClientTest: CrtXCBaseTestCase {

    func getClientBootstrap() throws -> ClientBootstrap {
        let elg = try EventLoopGroup(threadCount: 0, allocator: allocator)
        let hostResolver = try HostResolver(eventLoopGroup: elg,
                maxHosts: 8,
                maxTTL: 30,
                allocator: allocator)
        let bootstrap = try ClientBootstrap(eventLoopGroup: elg,
                hostResolver: hostResolver,
                allocator: allocator)
        return bootstrap
    }

    func testCreateIMDSClient() async throws {
        let bootstrap = try getClientBootstrap()
        let elg = try EventLoopGroup(threadCount: 1, allocator: allocator)
        let exponentialBackoffRetryOptions = CRTExponentialBackoffRetryOptions(eventLoopGroup: elg)
        let config = CRTStandardRetryOptions(exponentialBackoffRetryOptions: exponentialBackoffRetryOptions)
        let retryStrategy = try CRTAWSRetryStrategy(crtStandardRetryOptions: config, allocator: allocator)

        let imdsClient = try IMDSClient(bootstrap: bootstrap, retryStrategy: retryStrategy)
        let str = try await imdsClient.getAmiId()
        print(str)
    }


}
