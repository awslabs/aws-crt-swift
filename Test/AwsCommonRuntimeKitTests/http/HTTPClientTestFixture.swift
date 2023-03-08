//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
@testable import AwsCommonRuntimeKit

struct HTTPResponse {
    var statusCode: Int = -1
    var headers: [HTTPHeader] = [HTTPHeader]()
    var body: Data = Data()
    var error: CommonRunTimeError?
    var version: HTTPVersion?
}

class HTTPClientTestFixture: XCBaseTestCase {
    let TEST_DOC_LINE: String = """
                                This is a sample to prove that http downloads and uploads work. 
                                It doesn't really matter what's in here, 
                                we mainly just need to verify the downloads and uploads work.
                                """

    func sendHTTPRequest(method: String,
                         endpoint: String,
                         path: String = "/",
                         body: String = "",
                         expectedStatus: Int = 200,
                         connectionManager: HTTPClientConnectionManager,
                         expectedVersion: HTTPVersion = HTTPVersion.version_1_1,
                         requestVersion: HTTPVersion = HTTPVersion.version_1_1,
                         numRetries: UInt = 2,
                         onResponse: HTTPRequestOptions.OnResponse? = nil,
                         onBody: HTTPRequestOptions.OnIncomingBody? = nil,
                         onComplete: HTTPRequestOptions.OnStreamComplete? = nil) async throws -> HTTPResponse {

        var httpResponse = HTTPResponse()
        let semaphore = DispatchSemaphore(value: 0)

        let httpRequestOptions: HTTPRequestOptions
        if requestVersion == HTTPVersion.version_2 {
            httpRequestOptions = try getHTTP2RequestOptions(
                    method: method,
                    path: path,
                    authority: endpoint,
                    body: body,
                    response: &httpResponse,
                    semaphore: semaphore,
                    onResponse: onResponse,
                    onBody: onBody,
                    onComplete: onComplete)
        } else {
            httpRequestOptions = try getHTTPRequestOptions(
                    method: method,
                    endpoint: endpoint,
                    path: path,
                    body: body,
                    response: &httpResponse,
                    semaphore: semaphore,
                    onResponse: onResponse,
                    onBody: onBody,
                    onComplete: onComplete)
        }

        for i in 1...numRetries+1 where httpResponse.statusCode != expectedStatus {
            print("Attempt#\(i) to send an HTTP request")
            let connection = try await connectionManager.acquireConnection()
            XCTAssertTrue(connection.isOpen)
            httpResponse.version = connection.httpVersion
            XCTAssertEqual(connection.httpVersion, expectedVersion)
            let stream = try connection.makeRequest(requestOptions: httpRequestOptions)
            try stream.activate()
            semaphore.wait()
        }

        XCTAssertNil(httpResponse.error)
        XCTAssertEqual(httpResponse.statusCode, expectedStatus)
        return httpResponse
    }

    func sendHTTP2Request(method: String,
                          path: String,
                          scheme: String = "https",
                          authority: String,
                          body: String = "",
                          expectedStatus: Int = 200,
                          streamManager: HTTP2StreamManager,
                          numRetries: UInt = 2,
                          http2ManualDataWrites: Bool = false,
                          onResponse: HTTPRequestOptions.OnResponse? = nil,
                          onBody: HTTPRequestOptions.OnIncomingBody? = nil,
                          onComplete: HTTPRequestOptions.OnStreamComplete? = nil) async throws -> HTTPResponse {

        var httpResponse = HTTPResponse()
        let semaphore = DispatchSemaphore(value: 0)

        let httpRequestOptions = try getHTTP2RequestOptions(
                method: method,
                path: path,
                scheme: scheme,
                authority: authority,
                body: body,
                response: &httpResponse,
                semaphore: semaphore,
                onResponse: onResponse,
                onBody: onBody,
                onComplete: onComplete,
                http2ManualDataWrites: http2ManualDataWrites)

        for i in 1...numRetries+1 where httpResponse.statusCode != expectedStatus {
            print("Attempt#\(i) to send an HTTP request")
            let stream = try await streamManager.acquireStream(requestOptions: httpRequestOptions)
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
                           semaphore: DispatchSemaphore? = nil,
                           onResponse: HTTPRequestOptions.OnResponse? = nil,
                           onBody: HTTPRequestOptions.OnIncomingBody? = nil,
                           onComplete: HTTPRequestOptions.OnStreamComplete? = nil,
                           http2ManualDataWrites: Bool = false) -> HTTPRequestOptions {
        HTTPRequestOptions(request: request,
                onResponse: { status, headers in
                    response?.pointee.headers += headers
                    try onResponse?(status, headers)
                },

                onIncomingBody: { bodyChunk in
                    response?.pointee.body += bodyChunk
                    try onBody?(bodyChunk)
                },
                onStreamComplete: { result in
                    switch result{
                    case .success(let status):
                        response?.pointee.statusCode = Int(status)
                    case .failure(let error):
                        print("AWS_TEST_ERROR:\(String(describing: error))")
                        response?.pointee.error = error
                    }
                    onComplete?(result)
                    semaphore?.signal()
                },
                http2ManualDataWrites: http2ManualDataWrites)
    }


    func getHTTPRequestOptions(method: String,
                               endpoint: String,
                               path: String,
                               body: String = "",
                               response: UnsafeMutablePointer<HTTPResponse>? = nil,
                               semaphore: DispatchSemaphore? = nil,
                               headers: [HTTPHeader] = [HTTPHeader](),
                               onResponse: HTTPRequestOptions.OnResponse? = nil,
                               onBody: HTTPRequestOptions.OnIncomingBody? = nil,
                               onComplete: HTTPRequestOptions.OnStreamComplete? = nil
    ) throws -> HTTPRequestOptions {
        let httpRequest: HTTPRequest = try HTTPRequest(method: method, path: path, body: ByteBuffer(data: body.data(using: .utf8)!), allocator: allocator)
        httpRequest.addHeader(header: HTTPHeader(name: "Host", value: endpoint))
        httpRequest.addHeader(header: HTTPHeader(name: "Content-Length", value: String(body.count)))
        httpRequest.addHeaders(headers: headers)
        return getRequestOptions(
                request: httpRequest,
                response: response,
                semaphore: semaphore,
                onResponse: onResponse,
                onBody: onBody,
                onComplete: onComplete)
    }

    func getHTTP2RequestOptions(method: String,
                                path: String,
                                scheme: String = "https",
                                authority: String,
                                body: String = "",
                                manualDataWrites: Bool = false,
                                response: UnsafeMutablePointer<HTTPResponse>? = nil,
                                semaphore: DispatchSemaphore? = nil,
                                onResponse: HTTPRequestOptions.OnResponse? = nil,
                                onBody: HTTPRequestOptions.OnIncomingBody? = nil,
                                onComplete: HTTPRequestOptions.OnStreamComplete? = nil,
                                http2ManualDataWrites: Bool = false) throws -> HTTPRequestOptions {

        let http2Request = try HTTP2Request(body: ByteBuffer(data: body.data(using: .utf8)!), allocator: allocator)
        http2Request.addHeaders(headers: [
            HTTPHeader(name: ":method", value: method),
            HTTPHeader(name: ":path", value: path),
            HTTPHeader(name: ":scheme", value: scheme),
            HTTPHeader(name: ":authority", value: authority)
        ])
        return getRequestOptions(
                request: http2Request,
                response: response,
                semaphore: semaphore,
                onResponse: onResponse,
                onBody: onBody,
                onComplete: onComplete,
                http2ManualDataWrites: http2ManualDataWrites)
    }
}
