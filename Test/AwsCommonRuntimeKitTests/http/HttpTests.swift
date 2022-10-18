//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit
import AwsCCommon

class HttpTests: CrtXCBaseTestCase {
    let semaphore = DispatchSemaphore(value: 0)

    func testGetHttpRequest() async throws{
        let result = await sendGetHttpRequest()
        XCTAssertEqual(result, AWS_OP_SUCCESS)
    }

    func testGetHttpRequestAsync() async throws{
        let asyncResult = await sendGetHttpRequestAsync()
        XCTAssertEqual(asyncResult, AWS_OP_SUCCESS)
    }



    func getHttpConnection(host: String, ssh: Bool)  async throws -> HttpClientConnection {
        let tlsContextOptions = TlsContextOptions(defaultClientWithAllocator: allocator)
        try tlsContextOptions.setAlpnList("h2;http/1.1")
        let tlsContext = try TlsContext(options: tlsContextOptions, mode: .client, allocator: allocator)

        let tlsConnectionOptions = tlsContext.newConnectionOptions()

        try tlsConnectionOptions.setServerName(host)

        let elg = try EventLoopGroup(threadCount: 1, allocator: allocator)
        let hostResolver = try DefaultHostResolver(eventLoopGroup: elg, maxHosts: 8, maxTTL: 30, allocator: allocator)

        let bootstrap = try ClientBootstrap(eventLoopGroup: elg,
                hostResolver: hostResolver,
                shutDownCallbackOptions: nil,
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
        let connectionManager = try HttpClientConnectionManager(options: httpClientOptions)
        return try await connectionManager.acquireConnection()
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

    func sendGetHttpRequest() async -> Int32 {
        do {
            let url = URL(string: "https://aws-crt-test-stuff.s3.amazonaws.com/http_test_doc.txt")!
            guard let host = url.host else {
                print("no proper host was parsed from the url. quitting.")
                exit(EXIT_FAILURE)
            }

            let httpRequestOptions = try getHttpRequestOptions(method: "GET", path: url.path, host: host)

            let connection = try await getHttpConnection(host: host, ssh: true)

            let stream = try connection.makeRequest(requestOptions: httpRequestOptions)
            try stream.activate()
            semaphore.wait()
            let status_code = try stream.statusCode()
            XCTAssertEqual(status_code, 200)
            return AWS_OP_SUCCESS
        } catch let err {
            print(err)
            return AWS_OP_ERR
        }
    }


    func sendGetHttpRequestAsync() async -> Int32 {
        do {
            let url = URL(string: "https://aws-crt-test-stuff.s3.amazonaws.com/http_test_doc.txt")!
            guard let host = url.host else {
                print("no proper host was parsed from the url. quitting.")
                exit(EXIT_FAILURE)
            }

            let httpRequestOptions = try getHttpRequestOptions(method: "GET", path: url.path, host: host)

            let connection = try await getHttpConnection(host: host, ssh: true)

            async let status_code = try connection.makeRequestAsync(requestOptions: httpRequestOptions)
            // async, no need to manually wait for callback using semaphore. We can also make the stream.activate function async. If we want to expose HttpStream
            let status = try await status_code
            XCTAssertEqual(status, 200)
            return AWS_OP_SUCCESS
        } catch let err {
            print(err)
            return AWS_OP_ERR
        }
    }
}
