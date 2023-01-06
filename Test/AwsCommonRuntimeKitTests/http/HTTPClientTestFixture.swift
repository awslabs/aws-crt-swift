//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
@testable import AwsCommonRuntimeKit
import AwsCHttp

struct HTTPResponse {
    var statusCode: Int = -1
    var headers: [HTTPHeader] = [HTTPHeader]()
    var body: Data = Data()
    var error: CRTError?
}

class HTTPClientTestFixture: XCBaseTestCase {
    let semaphore = DispatchSemaphore(value: 0)

    func sendHttpRequest(method: String,
                         endpoint: String,
                         path: String = "/",
                         requestBody: String = "",
                         expectedStatus: Int = 200,
                         connectionManager: HTTPClientConnectionManager,
                         expectedVersion: HTTPVersion = HTTPVersion.version_1_1,
                         numRetries: UInt = 2) async throws -> HTTPResponse {
        var httpResponse = HTTPResponse()
        let httpRequestOptions = try getHTTPRequestOptions(
                method: method,
                endpoint: endpoint,
                path: path,
                body: requestBody,
                response: &httpResponse)

        for i in 1...numRetries+1 where httpResponse.statusCode != expectedStatus {
            print("Attempt#\(i) to send an HTTP request")
            let connection = try await connectionManager.acquireConnection()
            XCTAssertTrue(connection.isOpen)
            XCTAssertEqual(connection.httpVersion, expectedVersion)
            let stream = try connection.makeRequest(requestOptions: httpRequestOptions)
            try stream.activate()
            semaphore.wait()
        }

        XCTAssertNil(httpResponse.error)
        XCTAssertEqual(httpResponse.statusCode, expectedStatus)
        return httpResponse
    }

    func getHttpConnectionManager(endpoint: String,
                                  ssh: Bool = true,
                                  port: Int = 443,
                                  alpnList: [String] = ["http/1.1"],
                                  proxyOptions: HTTPProxyOptions? = nil,
                                  monitoringOptions: HTTPMonitoringOptions? = nil,
                                  socketOptions: SocketOptions = SocketOptions(socketType: .stream)) async throws -> HTTPClientConnectionManager {
        let tlsContextOptions = TLSContextOptions(allocator: allocator)
        tlsContextOptions.setAlpnList(alpnList)
        let tlsContext = try TLSContext(options: tlsContextOptions, mode: .client, allocator: allocator)
        var tlsConnectionOptions = TLSConnectionOptions(context: tlsContext, allocator: allocator)
        tlsConnectionOptions.serverName = endpoint

        let elg = try EventLoopGroup(threadCount: 1, allocator: allocator)
        let hostResolver = try HostResolver(eventLoopGroup: elg, maxHosts: 8, maxTTL: 30, allocator: allocator)
        let bootstrap = try ClientBootstrap(eventLoopGroup: elg,
                hostResolver: hostResolver,
                allocator: allocator)

        let httpClientOptions = HTTPClientConnectionOptions(clientBootstrap: bootstrap,
                hostName: endpoint,
                port: UInt16(port),
                proxyOptions: proxyOptions,
                socketOptions: socketOptions,
                tlsOptions: ssh ? tlsConnectionOptions : nil,
                monitoringOptions: monitoringOptions)
        return try HTTPClientConnectionManager(options: httpClientOptions)
    }

    func getRequestOptions(request: HTTPRequestBase,
                           response: UnsafeMutablePointer<HTTPResponse>? = nil,
                           onIncomingHeaders: HTTPRequestOptions.OnIncomingHeaders? = nil,
                           onBody: HTTPRequestOptions.OnIncomingBody? = nil,
                           onBlockDone: HTTPRequestOptions.OnIncomingHeadersBlockDone? = nil,
                           onComplete: HTTPRequestOptions.OnStreamComplete? = nil) -> HTTPRequestOptions {
        HTTPRequestOptions(request: request,
                onIncomingHeaders: onIncomingHeaders ?? { stream, headerBlock, headers in
                    for header in headers {
                        print(header.name + " : " + header.value)
                        response?.pointee.headers.append(header)
                    }
                },
                onIncomingHeadersBlockDone: onBlockDone ?? { stream, block in
                    print("onBlockDone")
                },
                onIncomingBody: onBody ?? { stream, bodyChunk in
                    print("onBody: \(bodyChunk)")
                    response?.pointee.body += bodyChunk
                },
                onStreamComplete: onComplete ?? { stream, error in
                    print("onComplete")
                    response?.pointee.error = error
                    let statusCode = try! stream.statusCode()
                    response?.pointee.statusCode = statusCode
                    self.semaphore.signal()
                })
    }

    // nil callbacks means use default
    func getHTTPRequestOptions(method: String,
                               endpoint: String,
                               path: String,
                               body: String = "",
                               response: UnsafeMutablePointer<HTTPResponse>? = nil,
                               headers: [HTTPHeader] = [HTTPHeader](),
                               onIncomingHeaders: HTTPRequestOptions.OnIncomingHeaders? = nil,
                               onBody: HTTPRequestOptions.OnIncomingBody? = nil,
                               onBlockDone: HTTPRequestOptions.OnIncomingHeadersBlockDone? = nil,
                               onComplete: HTTPRequestOptions.OnStreamComplete? = nil
                               ) throws -> HTTPRequestOptions {
        let httpRequest: HTTPRequest = try HTTPRequest(method: method, path: path, body: ByteBuffer(data: body.data(using: .utf8)!), allocator: allocator)
        httpRequest.addHeader(header: HTTPHeader(name: "Host", value: endpoint))
        httpRequest.addHeader(header: HTTPHeader(name: "Content-Length", value: String(body.count)))
        httpRequest.addHeaders(headers: headers)
        return getRequestOptions(
                request: httpRequest,
                response: response,
                onIncomingHeaders: onIncomingHeaders,
                onBody: onBody,
                onBlockDone: onBlockDone,
                onComplete: onComplete)
    }

    func getHTTP2RequestOptions(method: String,
                                path: String,
                                scheme: String = "https",
                                authority: String,
                                body: String = "",
                                manualDataWrites: Bool = false,
                                response: UnsafeMutablePointer<HTTPResponse>? = nil,
                                headers: [HTTPHeader] = [HTTPHeader](),
                                onIncomingHeaders: HTTPRequestOptions.OnIncomingHeaders? = nil,
                                onBody: HTTPRequestOptions.OnIncomingBody? = nil,
                                onBlockDone: HTTPRequestOptions.OnIncomingHeadersBlockDone? = nil,
                                onComplete: HTTPRequestOptions.OnStreamComplete? = nil) throws -> HTTPRequestOptions {

        let http2Request = try HTTP2Request(body: ByteBuffer(data: body.data(using: .utf8)!), allocator: allocator)
        var headers = headers
        headers.append(HTTPHeader(name: ":method", value: method))
        headers.append(HTTPHeader(name: ":path", value: path))
        headers.append(HTTPHeader(name: ":scheme", value: scheme))
        headers.append(HTTPHeader(name: ":authority", value: authority))
        headers.append(HTTPHeader(name: "content-length", value: String(body.count)))
        http2Request.addHeaders(headers: headers)
        return getRequestOptions(
                request: http2Request,
                response: response,
                onIncomingHeaders: onIncomingHeaders,
                onBody: onBody,
                onBlockDone: onBlockDone,
                onComplete: onComplete)
    }
}
