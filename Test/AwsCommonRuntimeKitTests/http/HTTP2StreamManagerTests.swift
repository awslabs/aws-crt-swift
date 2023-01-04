//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
@testable import AwsCommonRuntimeKit

class HTT2StreamManagerTests: HTTPClientTestFixture {
    let endpoint = "d1cz66xoahf9cl.cloudfront.net"; // Use cloudfront for HTTP/2
    let path = "/random_32_byte.data";

    func makeStreamManger(host: String, port: Int = 443) throws -> HTTP2StreamManager {
        let tlsContextOptions = TLSContextOptions(allocator: allocator)
        tlsContextOptions.setAlpnList(["h2", "http/1.1"])
        let tlsContext = try TLSContext(options: tlsContextOptions, mode: .client, allocator: allocator)

        var tlsConnectionOptions = TLSConnectionOptions(context: tlsContext, allocator: allocator)

        tlsConnectionOptions.serverName = host

        let elg = try EventLoopGroup(threadCount: 1, allocator: allocator)
        let hostResolver = try HostResolver(eventLoopGroup: elg, maxHosts: 8, maxTTL: 30, allocator: allocator)

        let bootstrap = try ClientBootstrap(eventLoopGroup: elg,
                hostResolver: hostResolver,
                allocator: allocator)

        let socketOptions = SocketOptions(socketType: .stream)
        let port = UInt16(443)
        let streamManager = try HTTP2StreamManager(
                options: HTTP2StreamManagerOptions(
                        clientBootstrap: bootstrap,
                        hostName: host,
                        port: UInt16(port),
                        proxyOptions: nil,
                        proxyEnvSettings: nil,
                        socketOptions: socketOptions,
                        tlsOptions: tlsConnectionOptions,
                        monitoringOptions: nil,
                        maxConnections: 2,
                        enableStreamManualWindowManagement: false,
                        shutdownCallback: nil,
                        http2PriorKnowledge: false,
                        http2InitialSettings: nil,
                        http2MaxClosedStreams: nil,
                        enableConnectionManualWindowManagement: false,
                        closeConnectionOnServerError: false,
                        connectionPingPeriodMs: nil,
                        connectionPingTimeoutMs: nil,
                        idealConcurrentStreamsPerConnection: nil,
                        maxConcurrentStreamsPerConnection: nil))
        return streamManager
    }

    func testCanCreateConnectionManager() throws {
        _ = try makeStreamManger(host: endpoint)
    }

    func makeHTTP2Request() throws -> HTTPRequestOptions {
        try getHTTPRequestOptions(method: "GET", endpoint: endpoint, path: path)
    }

    func testHTTP2Stream() async throws {
        let streamManager = try makeStreamManger(host: endpoint)
        let stream = try await streamManager.acquireStream(requestOptions: try makeHTTP2Request())
        semaphore.wait()
        XCTAssertEqual(try stream.statusCode(), 200)
    }

    // Test that the binding works not the actual functionality. C part has tests for functionality
    func testHTTP2StreamReset() async throws {
        let streamManager = try makeStreamManger(host: endpoint)
        let requestOptions = try makeHTTP2Request()
        let updatedRequestOptions = HTTPRequestOptions(
                request: requestOptions.request,
                onIncomingHeaders: { stream, headerBlock, headers in
                    let stream = stream as! HTTP2Stream
                    try! stream.resetStream(error: HTTP2Error.internalError)
                },
                onIncomingHeadersBlockDone: requestOptions.onIncomingHeadersBlockDone,
                onIncomingBody: requestOptions.onIncomingBody,
                onStreamComplete: requestOptions.onStreamComplete)
        let stream = try await streamManager.acquireStream(requestOptions: updatedRequestOptions)
        semaphore.wait()
    }

    func testHTTP2ParallelStreams() async throws {
        try await testHTTP2ParallelStreams(count: 5)
    }

    func testHTTP2ParallelStreams(count: Int) async throws {
        let streamManager = try makeStreamManger(host: endpoint)
        await withTaskGroup(of: Void.self) { taskGroup in
            for i in 1...count {
                taskGroup.addTask {
                    try! await self.testHTTP2Stream()
                }
            }
        }
    }

}
