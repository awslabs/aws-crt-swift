//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit

class HttpClientConnectionManagerTests: CrtXCBaseTestCase {

    func testCanCreateConnectionManager() async throws {
        let shutdownWasCalled = XCTestExpectation(description: "Shutdown callback was called")
        do {
            let host = "https://aws-crt-test-stuff.s3.amazonaws.com/http_test_doc.txt"
            let tlsContextOptions = TlsContextOptions(defaultClientWithAllocator: allocator)
            try tlsContextOptions.setAlpnList("h2;http/1.1")
            let tlsContext = try TlsContext(options: tlsContextOptions, mode: .client, allocator: allocator)

            let tlsConnectionOptions = tlsContext.newConnectionOptions()

            try tlsConnectionOptions.setServerName(host)

            let elg = try EventLoopGroup(threadCount: 1, allocator: allocator)
            let hostResolver = try DefaultHostResolver(eventLoopGroup: elg, maxHosts: 8, maxTTL: 30, allocator: allocator)

            let bootstrap = try ClientBootstrap(eventLoopGroup: elg,
                    hostResolver: hostResolver,
                    allocator: allocator)

            let socketOptions = SocketOptions(socketType: .stream)
            let port = UInt16(443)
            let httpClientOptions = HttpClientConnectionOptions(clientBootstrap: bootstrap,
                    hostName: host,
                    initialWindowSize: Int.max,
                    port: port,
                    proxyOptions: nil,
                    socketOptions: socketOptions,
                    tlsOptions: tlsConnectionOptions,
                    monitoringOptions: nil) {
                shutdownWasCalled.fulfill()
            }
            _ = try HttpClientConnectionManager(options: httpClientOptions)
        }
        wait(for: [shutdownWasCalled], timeout: 15)
    }
}
