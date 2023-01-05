//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
@testable import AwsCommonRuntimeKit

class HTT2StreamManagerTests: HTTPClientTestFixture {
    let endpoint = "d1cz66xoahf9cl.cloudfront.net"; // Use cloudfront for HTTP/2
    let path = "/random_32_byte.data";

    func testStreamManagerCreate() throws {
        let tlsContextOptions = TLSContextOptions(allocator: allocator)
        let tlsContext = try TLSContext(options: tlsContextOptions, mode: .client, allocator: allocator)
        let tlsConnectionOptions = TLSConnectionOptions(context: tlsContext, allocator: allocator)
        let elg = try EventLoopGroup(threadCount: 1, allocator: allocator)
        let hostResolver = try HostResolver(eventLoopGroup: elg, maxHosts: 8, maxTTL: 30, allocator: allocator)
        let bootstrap = try ClientBootstrap(eventLoopGroup: elg,
                hostResolver: hostResolver,
                allocator: allocator)
        let port = UInt16(443)

        let options = HTTP2StreamManagerOptions(
                        clientBootstrap: bootstrap,
                        hostName: endpoint,
                        port: port,
                        proxyOptions: HTTPProxyOptions(hostName: "localhost", port: 80),
                        proxyEnvSettings: HTTPProxyEnvSettings(proxyConnectionType: HTTPProxyConnectionType.forward),
                        socketOptions: SocketOptions(socketType: .stream),
                        tlsOptions: tlsConnectionOptions,
                        monitoringOptions: HTTPMonitoringOptions(minThroughputBytesPerSecond: 10, allowableThroughputFailureInterval: 20),
                        maxConnections: 30,
                        enableStreamManualWindowManagement: true,
                        shutdownCallback: {},
                        priorKnowledge: true,
                        initialSettings: HTTP2Settings(enablePush: true),
                        maxClosedStreams: 40,
                        enableConnectionManualWindowManagement: true,
                        closeConnectionOnServerError: true,
                        connectionPingPeriodMs: 50,
                        connectionPingTimeoutMs: 60,
                        idealConcurrentStreamsPerConnection: 70,
                        maxConcurrentStreamsPerConnection: 80)
        let shutdownCallbackCore = ShutdownCallbackCore(options.shutdownCallback)
        let shutdownOptions = shutdownCallbackCore.getRetainedShutdownOptions()
        options.withCStruct(shutdownOptions: shutdownOptions) {cOptions in
            XCTAssertNotNil(cOptions.bootstrap)
            XCTAssertNotNil(cOptions.socket_options)
            XCTAssertNotNil(cOptions.tls_connection_options)
            XCTAssertTrue(cOptions.http2_prior_knowledge)
            XCTAssertEqual(cOptions.host.toString(), endpoint)
            XCTAssertEqual(cOptions.port, port)
            XCTAssertNotNil(cOptions.initial_settings_array)
            XCTAssertEqual(cOptions.num_initial_settings, 1)
            XCTAssertEqual(cOptions.max_closed_streams, 40)
            XCTAssertTrue(cOptions.conn_manual_window_management)
            XCTAssertTrue(cOptions.enable_read_back_pressure)
            XCTAssertNotNil(cOptions.monitoring_options)
            XCTAssertNotNil(cOptions.proxy_options)
            XCTAssertNotNil(cOptions.proxy_ev_settings)
            XCTAssertNotNil(cOptions.shutdown_complete_user_data)
            XCTAssertNotNil(cOptions.shutdown_complete_callback)
            XCTAssertTrue(cOptions.close_connection_on_server_error)
            XCTAssertEqual(cOptions.connection_ping_period_ms, 50)
            XCTAssertEqual(cOptions.connection_ping_timeout_ms, 60)
            XCTAssertEqual(cOptions.ideal_concurrent_streams_per_connection, 70)
            XCTAssertEqual(cOptions.max_concurrent_streams_per_connection, 80)
            XCTAssertEqual(cOptions.max_connections, 30)
        }
        shutdownCallbackCore.release()
    }

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
                        socketOptions: socketOptions,
                        tlsOptions: tlsConnectionOptions))
        return streamManager
    }

    func testCanCreateConnectionManager() throws {
        _ = try makeStreamManger(host: endpoint)
    }

    func testHTTP2Stream() async throws {
        let semaphore = DispatchSemaphore(value: 0)
        let streamManager = try makeStreamManger(host: endpoint)
        let stream = try await streamManager.acquireStream(
                requestOptions: try getHTTPRequestOptions(
                        method: "GET",
                        endpoint: endpoint,
                        path: path, onComplete: { stream, error in
                    print("onComplete")
                    XCTAssertNil(error)
                    semaphore.signal()
                }))
        semaphore.wait()
        XCTAssertEqual(try stream.statusCode(), 200)
    }

    // Test that the binding works not the actual functionality. C part has tests for functionality
    func testHTTP2StreamReset() async throws {
        let streamManager = try makeStreamManger(host: endpoint)
        let requestOptions = try getHTTPRequestOptions(
                method: "GET",
                endpoint: endpoint,
                path: path
        )
        let updatedRequestOptions = HTTPRequestOptions(
                request: requestOptions.request,
                onIncomingHeaders: { stream, headerBlock, headers in
                    let stream = stream as! HTTP2Stream
                    try! stream.resetStream(error: HTTP2Error.internalError)
                },
                onIncomingHeadersBlockDone: requestOptions.onIncomingHeadersBlockDone,
                onIncomingBody: requestOptions.onIncomingBody,
                onStreamComplete: requestOptions.onStreamComplete)
        _ = try await streamManager.acquireStream(requestOptions: updatedRequestOptions)
        semaphore.wait()
    }

    func testHTTP2ParallelStreams() async throws {
        try await testHTTP2ParallelStreams(count: 5)
    }

    func testHTTP2ParallelStreams(count: Int) async throws {
        await withTaskGroup(of: Void.self) { taskGroup in
            for _ in 1...count {
                taskGroup.addTask {
                    try! await self.testHTTP2Stream()
                }
            }
        }
    }
}