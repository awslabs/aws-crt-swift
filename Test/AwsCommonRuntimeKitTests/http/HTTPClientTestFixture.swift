//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
@testable import AwsCommonRuntimeKit
import AwsCHttp

struct HTTPResponse {
    var statusCode: Int = -1
    var headers: [HTTPHeader] = [HTTPHeader]()
    var body: Data = Data()
}

class HTTPClientTestFixture: XCBaseTestCase {
    let semaphore = DispatchSemaphore(value: 0)

    func sendHttpRequest(method: String,
                         endpoint: String,
                         path: String = "/",
                         requestBody: String = "",
                         expectedStatus: Int = 200,
                         connectionManager: HTTPClientConnectionManager,
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
            let stream = try connection.makeRequest(requestOptions: httpRequestOptions)
            try stream.activate()
            semaphore.wait()
        }

        XCTAssertEqual(httpResponse.statusCode, expectedStatus)
        return httpResponse
    }

    func getHttpConnectionManager(endpoint: String,
                                  ssh: Bool = true,
                                  port: Int = 443,
                                  alpnList: [String] = ["h2","http/1.1"],
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



    func getHTTPRequestOptions(method: String,
                               endpoint: String,
                               path: String,
                               body: String = "",
                               response: UnsafeMutablePointer<HTTPResponse>? = nil,
                               headers: [HTTPHeader] = [HTTPHeader]()) throws -> HTTPRequestOptions {
        let httpRequest: HTTPRequest = try HTTPRequest(method: method, path: path, body: ByteBuffer(data: body.data(using: .utf8)!), allocator: allocator)
        httpRequest.addHeader(header: HTTPHeader(name: "Host", value: endpoint))
        httpRequest.addHeader(header: HTTPHeader(name: "Content-Length", value: String(body.count)))
        httpRequest.addHeaders(headers: headers)
        let onIncomingHeaders: HTTPRequestOptions.OnIncomingHeaders = { stream, headerBlock, headers in
            for header in headers {
                print(header.name + " : " + header.value)
                response?.pointee.headers.append(header)
            }
        }

        let onBody: HTTPRequestOptions.OnIncomingBody = { stream, bodyChunk in
            print("onBody: \(bodyChunk)")
            response?.pointee.body += bodyChunk
        }

        let onBlockDone: HTTPRequestOptions.OnIncomingHeadersBlockDone = { stream, block in
            print("onBlockDone")
        }

        let onComplete: HTTPRequestOptions.OnStreamComplete = { stream, error in
            print("onComplete")
            XCTAssertNil(error)
            let statusCode = try! stream.statusCode()
            response?.pointee.statusCode = statusCode
            self.semaphore.signal()
        }

        let requestOptions = HTTPRequestOptions(request: httpRequest,
                onIncomingHeaders: onIncomingHeaders,
                onIncomingHeadersBlockDone: onBlockDone,
                onIncomingBody: onBody,
                onStreamComplete: onComplete)
        return requestOptions
    }
}
