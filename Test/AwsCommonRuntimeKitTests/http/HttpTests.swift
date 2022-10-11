//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit
import AwsCCommon

class HttpTests: CrtXCBaseTestCase {

    func testGetHttpRequest() async throws{
        let result = await sendGetHttpRequest()
        XCTAssertEqual(result, AWS_OP_SUCCESS)
    }

    func getHttpConnection(host: String, port: UInt16)  async throws -> HttpClientConnection {
        let tlsContextOptions = TlsContextOptions(defaultClientWithAllocator: allocator)
        try tlsContextOptions.setAlpnList("h2;http/1.1")
        let tlsContext = try TlsContext(options: tlsContextOptions, mode: .client, allocator: allocator)

        let tlsConnectionOptions = tlsContext.newConnectionOptions()

        try tlsConnectionOptions.setServerName(host)

        let elg = EventLoopGroup(threadCount: 1, allocator: allocator)
        let hostResolver = DefaultHostResolver(eventLoopGroup: elg, maxHosts: 8, maxTTL: 30, allocator: allocator)

        let bootstrap = try ClientBootstrap(eventLoopGroup: elg,
                hostResolver: hostResolver,
                callbackData: nil,
                allocator: allocator)

        let socketOptions = SocketOptions(socketType: .stream)
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

    func sendGetHttpRequest() async -> Int32 {
        do {
            let url = URL(string: "https://aws-crt-test-stuff.s3.amazonaws.com/http_test_doc.txt")!
            guard let host = url.host else {
                print("no proper host was parsed from the url. quitting.")
                exit(EXIT_FAILURE)
            }
            let port = UInt16(443)

            let semaphore = DispatchSemaphore(value: 0)

            let httpRequest: HttpRequest = try HttpRequest(allocator: allocator)
            httpRequest.method = "GET"
            let path = url.path == "" ? "/" : url.path
            httpRequest.path = path

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

            }

            let onComplete: HttpRequestOptions.OnStreamComplete = { stream, error in
                XCTAssertEqual(error.code, AWS_OP_SUCCESS)
                XCTAssertEqual(try! stream.statusCode(), 200)
                print(error.message)
                semaphore.signal()
            }

            do {
                let connection = try await getHttpConnection(host: host, port: port)
                let requestOptions = HttpRequestOptions(request: httpRequest,
                        onIncomingHeaders: onIncomingHeaders,
                        onIncomingHeadersBlockDone: onBlockDone,
                        onIncomingBody: onBody,
                        onStreamComplete: onComplete)
                let stream = try connection.makeRequest(requestOptions: requestOptions)
                try stream.activate()
//                //try connection?.close()
//                let stream2 = try connection.makeRequest(requestOptions: requestOptions)
//                try stream2.activate()
            } catch {
                print("connection has shut down with error: \(error.localizedDescription)" )
                semaphore.signal()
            }

            semaphore.wait()

            return AWS_OP_SUCCESS
        } catch let err {

            print(err)
            return AWS_OP_ERR
        }
    }

}
