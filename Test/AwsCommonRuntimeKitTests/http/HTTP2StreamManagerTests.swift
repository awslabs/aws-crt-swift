////  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
////  SPDX-License-Identifier: Apache-2.0.

import XCTest
@testable import AwsCommonRuntimeKit

class HTT2StreamManagerTests {
    let endpoint = "d1cz66xoahf9cl.cloudfront.net"; // Use cloudfront for HTTP/2
    let path = "/random_32_byte.data";

    func testStreamManagerCreate() throws {
        let tlsContextOptions = TLSContextOptions()
        let tlsContext = try TLSContext(options: tlsContextOptions, mode: .client)
        let tlsConnectionOptions = TLSConnectionOptions(context: tlsContext)
        let elg = try EventLoopGroup(threadCount: 1)
        let hostResolver = try HostResolver(eventLoopGroup: elg, maxHosts: 8, maxTTL: 30)
        let bootstrap = try ClientBootstrap(eventLoopGroup: elg,
                hostResolver: hostResolver)
        let port = UInt32(443)

        let options = HTTP2StreamManagerOptions(
                        clientBootstrap: bootstrap,
                        hostName: endpoint,
                        port: port,
                        maxConnections: 30,
                        proxyOptions: HTTPProxyOptions(hostName: "localhost", port: 80),
                        proxyEnvSettings: HTTPProxyEnvSettings(proxyConnectionType: HTTPProxyConnectionType.forward),
                        socketOptions: SocketOptions(socketType: .stream),
                        tlsOptions: tlsConnectionOptions,
                        monitoringOptions: HTTPMonitoringOptions(minThroughputBytesPerSecond: 10, allowableThroughputFailureInterval: 20),
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
        let tlsContextOptions = TLSContextOptions()
        tlsContextOptions.setAlpnList(["h2"])
        let tlsContext = try TLSContext(options: tlsContextOptions, mode: .client)

        var tlsConnectionOptions = TLSConnectionOptions(context: tlsContext)

        tlsConnectionOptions.serverName = host

        let elg = try EventLoopGroup(threadCount: 1)
        let hostResolver = try HostResolver(eventLoopGroup: elg, maxHosts: 8, maxTTL: 30)

        let bootstrap = try ClientBootstrap(eventLoopGroup: elg,
                hostResolver: hostResolver)

        let socketOptions = SocketOptions(socketType: .stream)
        let port = UInt32(443)
        let streamManager = try HTTP2StreamManager(
                options: HTTP2StreamManagerOptions(
                        clientBootstrap: bootstrap,
                        hostName: host,
                        port: UInt32(port),
                        maxConnections: 5,
                        socketOptions: socketOptions,
                        tlsOptions: tlsConnectionOptions))
        return streamManager
    }

    func testCanCreateConnectionManager() throws {
        _ = try makeStreamManger(host: endpoint)
    }

    func testHTTP2Stream() async throws {
        let streamManager = try makeStreamManger(host: endpoint)
        _ = try await HTTPClientTestFixture.sendHTTP2Request(method: "GET", path: path, authority: endpoint, streamManager: streamManager)
    }

    func testHTTP2StreamUpload() async throws {
        let streamManager = try makeStreamManger(host: "nghttp2.org")
        let semaphore = Semaphore(value: 0)
        var httpResponse = HTTPResponse()
        var onCompleteCalled = false
        let testBody = "testBody"
        let http2RequestOptions = try HTTPClientTestFixture.getHTTP2RequestOptions(
                method: "PUT",
                path: "/httpbin/put",
                authority: "nghttp2.org",
                body: testBody,
                response: &httpResponse,
                semaphore: semaphore,
                onComplete: { _ in
                    onCompleteCalled = true
                },
                http2ManualDataWrites: true)

        let stream = try await streamManager.acquireStream(requestOptions: http2RequestOptions)
        XCTAssertFalse(onCompleteCalled)
        let metrics = streamManager.fetchMetrics()
        XCTAssertTrue(metrics.availableConcurrency > 0)
        XCTAssertTrue(metrics.leasedConcurrency > 0)
        let data = HTTPClientTestFixture.TEST_DOC_LINE.data(using: .utf8)!
        for chunk in data.chunked(into: 5) {
            try await stream.writeChunk(chunk: chunk, endOfStream: false)
            XCTAssertFalse(onCompleteCalled)
        }

        XCTAssertFalse(onCompleteCalled)
        // Sleep for 5 seconds to make sure onComplete is not triggerred until endOfStream is true
        try await Task.sleep(nanoseconds: 5_000_000_000)
        XCTAssertFalse(onCompleteCalled)
        try await stream.writeChunk(chunk: Data(), endOfStream: true)
        await semaphore.wait()
        XCTAssertTrue(onCompleteCalled)
        XCTAssertNil(httpResponse.error)
        XCTAssertEqual(httpResponse.statusCode, 200)

        // Parse json body
        struct Response: Codable {
            let data: String
        }

        let body: Response = try! JSONDecoder().decode(Response.self, from: httpResponse.body)
        XCTAssertEqual(body.data, testBody + HTTPClientTestFixture.TEST_DOC_LINE)
    }

    // Test that the binding works not the actual functionality. C part has tests for functionality
    func testHTTP2StreamReset() async throws {
        let streamManager = try makeStreamManger(host: endpoint)
        let http2RequestOptions = try HTTPClientTestFixture.getHTTP2RequestOptions(
                method: "PUT",
                path: "/httpbin/put",
                authority: "nghttp2.org")

        let stream = try await streamManager.acquireStream(requestOptions: http2RequestOptions)
        try stream.resetStream(error: HTTP2Error.internalError)
    }

    func testHTTP2ParallelStreams() async throws {
        try await testHTTP2ParallelStreams(count: 10)
    }

    func testHTTP2ParallelStreams(count: Int) async throws {
        let streamManager = try makeStreamManger(host: "nghttp2.org")
        return await withTaskGroup(of: Void.self) { taskGroup in
            for _ in 1...count {
                taskGroup.addTask {
                    _ = try! await HTTPClientTestFixture.sendHTTP2Request(method: "GET", path: "/httpbin/get", authority: "nghttp2.org", streamManager: streamManager)
                }
            }
        }
    }
}
