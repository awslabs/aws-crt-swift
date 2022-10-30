//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
@testable import AwsCommonRuntimeKit
import AwsCCommon

class HttpTests: CrtXCBaseTestCase {
    let semaphore = DispatchSemaphore(value: 0)

    func testGetHttpRequest() async throws {
        try await sendGetHttpRequest()
    }

    func sendGetHttpRequest() async throws {
        let url = URL(string: "https://aws-crt-test-stuff.s3.amazonaws.com/http_test_doc.txt")!
        guard let host = url.host else {
            print("no proper host was parsed from the url. quitting.")
            exit(EXIT_FAILURE)
        }

        let httpRequestOptions = try getHttpRequestOptions(method: "GET", path: url.path, host: host)

        let connectionManager = try await getHttpConnectionManager(host: host, ssh: true)
        let connection = try await connectionManager.acquireConnection()

        let stream = try connection.makeRequest(requestOptions: httpRequestOptions)
        try stream.activate()
        semaphore.wait()
        let status_code = try stream.statusCode()
        XCTAssertEqual(status_code, 200)
    }

    func testHttpStreamIsReleasedIfNotActivated() async throws {
        do {
            let url = URL(string: "https://aws-crt-test-stuff.s3.amazonaws.com/http_test_doc.txt")!
            guard let host = url.host else {
                print("no proper host was parsed from the url. quitting.")
                exit(EXIT_FAILURE)
            }

            let httpRequestOptions = try getHttpRequestOptions(method: "GET", path: url.path, host: host)
            let connectionManager = try await getHttpConnectionManager(host: host, ssh: true)
            let connection = try await connectionManager.acquireConnection()
            _ = try connection.makeRequest(requestOptions: httpRequestOptions)
        } catch let err {
            print(err)
        }
    }

    func getHttpConnectionManager(host: String, ssh: Bool) async throws -> HttpClientConnectionManager {
        let tlsContextOptions = TlsContextOptions(defaultClientWithAllocator: allocator)
        try tlsContextOptions.setAlpnList("h2;http/1.1")
        let tlsContext = try TlsContext(options: tlsContextOptions, mode: .client, allocator: allocator)
        var tlsConnectionOptions = tlsContext.newConnectionOptions()
        tlsConnectionOptions.serverName = host

        let elg = try EventLoopGroup(threadCount: 1, allocator: allocator)
        let hostResolver = try HostResolver(eventLoopGroup: elg, maxHosts: 8, maxTTL: 30, allocator: allocator)
        let bootstrap = try ClientBootstrap(eventLoopGroup: elg,
                hostResolver: hostResolver,
                allocator: allocator)

        let socketOptions = SocketOptions(socketType: .stream)
        let port = ssh ? UInt16(443) : UInt16(80)
        let httpClientOptions = HttpClientConnectionOptions(clientBootstrap: bootstrap,
                hostName: host,
                initialWindowSize: Int.max,
                port: port,
                proxyOptions: nil,
                socketOptions: socketOptions,
                tlsOptions: tlsConnectionOptions,
                monitoringOptions: nil)
        return try HttpClientConnectionManager(options: httpClientOptions)
    }

    func getHeaders(host: String) throws -> HttpHeaders {
        let headers = try HttpHeaders(allocator: allocator)
        XCTAssertTrue(headers.add(name: "Host", value: host))
        return headers;
    }

    func getHttpRequestOptions(method: String, path: String, host: String) throws -> HttpRequestOptions {

        let httpRequest: HttpRequest = try HttpRequest(allocator: allocator)
        httpRequest.method = method
        httpRequest.path = path == "" ? "/" : path

        httpRequest.addHeaders(headers: try getHeaders(host: host))
        let onIncomingHeaders: HttpRequestOptions.OnIncomingHeaders = { stream, headerBlock, headers in
            let allHeaders = headers.getAll()
            for header in allHeaders {
                print(header.name + " : " + header.value)
            }
        }

        let onBody: HttpRequestOptions.OnIncomingBody = { stream, bodyChunk in
            print("onBody: \(bodyChunk)")
        }

        let onBlockDone: HttpRequestOptions.OnIncomingHeadersBlockDone = { stream, block in
            print("onBlockDone")
        }

        let onComplete: HttpRequestOptions.OnStreamComplete = { stream, error in
            print("onComplete")
            XCTAssertEqual(error.code, AWS_OP_SUCCESS)
            XCTAssertEqual(try! stream.statusCode(), 200)
            self.semaphore.signal()
        }

        let requestOptions = HttpRequestOptions(request: httpRequest,
                onIncomingHeaders: onIncomingHeaders,
                onIncomingHeadersBlockDone: onBlockDone,
                onIncomingBody: onBody,
                onStreamComplete: onComplete)
        return requestOptions
    }
}
