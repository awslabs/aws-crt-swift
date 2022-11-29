//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
@testable import AwsCommonRuntimeKit
import AwsCCommon

class HttpTests: CrtXCBaseTestCase {
    let semaphore = DispatchSemaphore(value: 0)
    let TEST_DOC_LINE: String = """
                                This is a sample to prove that http downloads and uploads work. 
                                It doesn't really matter what's in here, 
                                we mainly just need to verify the downloads and uploads work.
                                """

    func testGetHttpRequest() async throws {
        try await sendHttpRequest(method: "GET", endpoint: "httpbin.org", path: "/get")
        try await sendHttpRequest(method: "GET", endpoint: "httpbin.org", path: "/delete", expectedStatus: 405)
        try await sendHttpRequest(method: "GET", endpoint: "httpbin.org", path: "/get", ssh: false, port: 80)

    }

    func testPutHttpRequest() async throws {
        try await sendHttpRequest(method: "PUT", endpoint: "httpbin.org", path: "/anything", requestBody: TEST_DOC_LINE)
    }


    func sendHttpRequest(method: String,
                         endpoint: String,
                         path: String,
                         requestBody: String = "",
                         expectedStatus: Int = 200,
                         ssh: Bool = true,
                         port: Int = 443) async throws {
        let httpRequestOptions = try getHttpRequestOptions(method: method, endpoint: endpoint, path: path, body: requestBody, expectedStatusCode: expectedStatus)

        let connectionManager = try await getHttpConnectionManager(endpoint: endpoint, ssh: ssh, port: port)
        let connection = try await connectionManager.acquireConnection()

        let stream = try connection.makeRequest(requestOptions: httpRequestOptions)
        try stream.activate()
        semaphore.wait()
        let status_code = try stream.statusCode()
        XCTAssertEqual(status_code, expectedStatus)
    }

    func testHttpStreamIsReleasedIfNotActivated() async throws {
        do {
            let url = URL(string: "https://aws-crt-test-stuff.s3.amazonaws.com/http_test_doc.txt")!
            guard let host = url.host else {
                print("no proper host was parsed from the url. quitting.")
                exit(EXIT_FAILURE)
            }

            let httpRequestOptions = try getHttpRequestOptions(method: "GET", endpoint: host, path: url.path)
            let connectionManager = try await getHttpConnectionManager(endpoint: host, ssh: true, port: 443)
            let connection = try await connectionManager.acquireConnection()
            _ = try connection.makeRequest(requestOptions: httpRequestOptions)
        } catch let err {
            print(err)
        }
    }

    func getHttpConnectionManager(endpoint: String, ssh: Bool, port: Int) async throws -> HttpClientConnectionManager {
        let tlsContextOptions = TlsContextOptions(allocator: allocator)
        tlsContextOptions.setAlpnList(["http/1.1"])
        let tlsContext = try TlsContext(options: tlsContextOptions, mode: .client, allocator: allocator)
        var tlsConnectionOptions = TlsConnectionOptions(context: tlsContext, allocator: allocator)
        tlsConnectionOptions.serverName = endpoint

        let elg = try EventLoopGroup(threadCount: 1, allocator: allocator)
        let hostResolver = try HostResolver(eventLoopGroup: elg, maxHosts: 8, maxTTL: 30, allocator: allocator)
        let bootstrap = try ClientBootstrap(eventLoopGroup: elg,
                hostResolver: hostResolver,
                allocator: allocator)

        let socketOptions = SocketOptions(socketType: .stream)

        let httpClientOptions = HttpClientConnectionOptions(clientBootstrap: bootstrap,
                hostName: endpoint,
                initialWindowSize: Int.max,
                port: UInt16(port),
                proxyOptions: nil,
                socketOptions: socketOptions,
                tlsOptions: ssh ? tlsConnectionOptions : nil,
                monitoringOptions: nil)
        return try HttpClientConnectionManager(options: httpClientOptions)
    }

    struct Response: Codable {
        let data: String
    }

    func getHttpRequestOptions(method: String,
                               endpoint: String,
                               path: String,
                               body: String = "",
                               expectedStatusCode: Int = 200) throws -> HttpRequestOptions {
        let httpRequest: HttpRequest = try HttpRequest(method: method, path: path, body: ByteBuffer(data: body.data(using: .utf8)!), allocator: allocator)

        let headers = try HttpHeaders(allocator: allocator)
        XCTAssertTrue(headers.add(name: "Host", value: endpoint))
        XCTAssertTrue(headers.add(name: "Content-Length", value: String(body.count)))
        httpRequest.addHeaders(headers: headers)

        let onIncomingHeaders: HttpRequestOptions.OnIncomingHeaders = { stream, headerBlock, headers in
            let allHeaders = headers.getAll()
            for header in allHeaders {
                print(header.name + " : " + header.value)
            }
        }

        let onBody: HttpRequestOptions.OnIncomingBody = { stream, bodyChunk in
            print("onBody: \(bodyChunk)")

            if !body.isEmpty {
                let response: Response = try! JSONDecoder().decode(Response.self, from: bodyChunk)
                XCTAssertEqual(response.data, body)
            }
        }

        let onBlockDone: HttpRequestOptions.OnIncomingHeadersBlockDone = { stream, block in
            print("onBlockDone")
        }

        let onComplete: HttpRequestOptions.OnStreamComplete = { stream, error in
            print("onComplete")
            XCTAssertNil(error)
            XCTAssertEqual(error, nil)
            XCTAssertEqual(try! stream.statusCode(), expectedStatusCode)
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
