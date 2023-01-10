//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
@testable import AwsCommonRuntimeKit

class HTTPClientConnectionOptionsTests: XCBaseTestCase {

    func testCreateHttpClientOptions() throws {
        let context = try TLSContext(options: TLSContextOptions(allocator: allocator), mode: TLSMode.client)
        let tlsOptions = TLSConnectionOptions(context: context, allocator: allocator)

        let elg = try EventLoopGroup(allocator: allocator)
        let resolver = try HostResolver(eventLoopGroup: elg,
                maxHosts: 8,
                maxTTL: 30,
                allocator: allocator)

        let clientBootstrap = try ClientBootstrap(eventLoopGroup: elg,
                hostResolver: resolver,
                allocator: allocator)

        let shutdownCallback = {
        }

        let httpClientOptions = HTTPClientConnectionOptions(clientBootstrap: clientBootstrap,
                hostName: "test",
                initialWindowSize: 100,
                port: UInt16(80),
                proxyOptions: HTTPProxyOptions(hostName: "test", port: 8080),
                proxyEnvSettings: HTTPProxyEnvSettings(envVarType: HTTPProxyEnvType.disable),
                socketOptions: SocketOptions(socketType: .stream),
                tlsOptions: tlsOptions,
                monitoringOptions: HTTPMonitoringOptions(minThroughputBytesPerSecond: 10),
                maxConnections: 10,
                enableManualWindowManagement: true,
                maxConnectionIdleMs: 100,
                shutdownCallback: shutdownCallback)

        let shutdownCallbackCore = ShutdownCallbackCore(shutdownCallback)
        let shutdownOptions = shutdownCallbackCore.getRetainedShutdownOptions()
        httpClientOptions.withCStruct(shutdownOptions: shutdownOptions) { clientOptions in
            XCTAssertEqual(clientOptions.host.toString(), "test")
            XCTAssertEqual(clientOptions.initial_window_size, 100)
            XCTAssertEqual(clientOptions.port, 80)

            XCTAssertNotNil(clientOptions.proxy_options)
            XCTAssertEqual(clientOptions.proxy_options.pointee.port, 8080)

            XCTAssertNotNil(clientOptions.proxy_ev_settings)
            XCTAssertEqual(clientOptions.proxy_ev_settings.pointee.env_var_type, HTTPProxyEnvType.disable.rawValue)

            XCTAssertNotNil(clientOptions.socket_options)
            XCTAssertEqual(clientOptions.socket_options.pointee.type, SocketType.stream.rawValue)
            XCTAssertNotNil(clientOptions.tls_connection_options)

            XCTAssertNotNil(clientOptions.monitoring_options)
            XCTAssertEqual(clientOptions.monitoring_options.pointee.minimum_throughput_bytes_per_second, 10)

            XCTAssertTrue(clientOptions.enable_read_back_pressure)
            XCTAssertEqual(clientOptions.max_connection_idle_in_milliseconds, 100)
            XCTAssertNotNil(clientOptions.shutdown_complete_callback)
            XCTAssertNotNil(clientOptions.shutdown_complete_user_data)
        }
        shutdownCallbackCore.release()
    }
}
