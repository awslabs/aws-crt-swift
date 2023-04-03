//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit

class HTTPClientConnectionManagerTests: XCBaseTestCase {

    func testCanCreateConnectionManager() async throws {
        let shutdownWasCalled = XCTestExpectation(description: "Shutdown callback was called")
        do {
            let host = "https://aws-crt-test-stuff.s3.amazonaws.com/http_test_doc.txt"
            let tlsContextOptions = TLSContextOptions()
            tlsContextOptions.setAlpnList(["h2","http/1.1"])
            let tlsContext = try TLSContext(options: tlsContextOptions, mode: .client)

            var tlsConnectionOptions = TLSConnectionOptions(context: tlsContext)

            tlsConnectionOptions.serverName = host

            let elg = try EventLoopGroup(threadCount: 1)
            let hostResolver = try HostResolver(eventLoopGroup: elg, maxHosts: 8, maxTTL: 30)

            let bootstrap = try ClientBootstrap(eventLoopGroup: elg,
                    hostResolver: hostResolver)

            let socketOptions = SocketOptions(socketType: .stream)
            let port = UInt16(443)
            let httpClientOptions = HTTPClientConnectionOptions(clientBootstrap: bootstrap,
                    hostName: host,
                    initialWindowSize: Int.max,
                    port: port,
                    proxyOptions: HTTPProxyOptions(hostName: "localhost", port: 80),
                    socketOptions: socketOptions,
                    tlsOptions: tlsConnectionOptions,
                    monitoringOptions: nil) {
                shutdownWasCalled.fulfill()
            }
            _ = try HTTPClientConnectionManager(options: httpClientOptions)
        }
        wait(for: [shutdownWasCalled], timeout: 15)
    }
}
