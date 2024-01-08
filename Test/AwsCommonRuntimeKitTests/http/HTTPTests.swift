//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
@testable import AwsCommonRuntimeKit
import AwsCCommon
import AwsCHttp

class HTTPTests: HTTPClientTestFixture {
    let host = "postman-echo.com"
    let getPath = "/get"

    func testGetHTTPSRequest() async throws {
        let connectionManager = try await getHttpConnectionManager(endpoint: host, ssh: true, port: 443)
        _ = try await sendHTTPRequest(method: "GET", endpoint: host, path: getPath, connectionManager: connectionManager)
        _ = try await sendHTTPRequest(method: "GET", endpoint: host, path: "/delete", expectedStatus: 404, connectionManager: connectionManager)
    }

    func testGetHTTPRequest() async throws {
        let connectionManager = try await getHttpConnectionManager(endpoint: host, ssh: false, port: 80)
        _ = try await sendHTTPRequest(method: "GET", endpoint: host, path: getPath, connectionManager: connectionManager)
    }

    func testPutHTTPRequest() async throws {
        let connectionManager = try await getHttpConnectionManager(endpoint: host, ssh: true, port: 443)
        let response = try await sendHTTPRequest(
                method: "PUT",
                endpoint: host,
                path: "/put",
                body: TEST_DOC_LINE,
                connectionManager: connectionManager)

        // Parse json body
        struct Response: Codable {
            let data: String
        }
        let body: Response = try! JSONDecoder().decode(Response.self, from: response.body)
        XCTAssertEqual(body.data, TEST_DOC_LINE)
    }

    func testHTTPChunkTransferEncoding() async throws {
        let connectionManager = try await getHttpConnectionManager(endpoint: host, alpnList: ["http/1.1"])
        let semaphore = DispatchSemaphore(value: 0)
        var httpResponse = HTTPResponse()
        var onCompleteCalled = false
        let httpRequestOptions = try getHTTPRequestOptions(
                method: "PUT",
                endpoint: host,
                path: "/put",
                response: &httpResponse,
                semaphore: semaphore,
                onComplete: { _ in
                    onCompleteCalled = true
                },
                useChunkedEncoding: true)
        let connection = try await connectionManager.acquireConnection()
        let streamBase = try connection.makeRequest(requestOptions: httpRequestOptions)
        let stream = streamBase as! HTTP1Stream
        try stream.activate()
        XCTAssertFalse(onCompleteCalled)
        let data = TEST_DOC_LINE.data(using: .utf8)!
        for chunk in data.chunked(into: 5) {
            try await stream.writeData(data: chunk)
            XCTAssertFalse(onCompleteCalled)
        }

        XCTAssertFalse(onCompleteCalled)
        // Sleep for 5 seconds to make sure onComplete is not triggerred
        try await Task.sleep(nanoseconds: 5_000_000_000)
        XCTAssertFalse(onCompleteCalled)
        try await stream.writeData(data: Data())
        semaphore.wait()
        XCTAssertTrue(onCompleteCalled)
        XCTAssertNil(httpResponse.error)
        XCTAssertEqual(httpResponse.statusCode, 200)

        // Parse json body
        struct Response: Codable {
            let data: String
        }

        let body: Response = try! JSONDecoder().decode(Response.self, from: httpResponse.body)
        XCTAssertEqual(body.data, TEST_DOC_LINE)
    }

    func testHTTPStreamIsReleasedIfNotActivated() async throws {
        do {
            let httpRequestOptions = try getHTTPRequestOptions(method: "GET", endpoint: host, path: getPath)
            let connectionManager = try await getHttpConnectionManager(endpoint: host, ssh: true, port: 443)
            let connection = try await connectionManager.acquireConnection()
            _ = try connection.makeRequest(requestOptions: httpRequestOptions)
        } catch let err {
            print(err)
        }
    }

    func testStreamLivesUntilComplete() async throws {
        let semaphore = DispatchSemaphore(value: 0)

        do {
            let httpRequestOptions = try getHTTPRequestOptions(method: "GET", endpoint: host, path: getPath, semaphore: semaphore)
            let connectionManager = try await getHttpConnectionManager(endpoint: host, ssh: true, port: 443)
            let connection = try await connectionManager.acquireConnection()
            let stream = try connection.makeRequest(requestOptions: httpRequestOptions)
            try stream.activate()
        }
        semaphore.wait()
    }

    func testManagerLivesUntilComplete() async throws {
        var connection: HTTPClientConnection! = nil
        let semaphore = DispatchSemaphore(value: 0)

        do {
            let connectionManager = try await getHttpConnectionManager(endpoint: host, ssh: true, port: 443)
            connection = try await connectionManager.acquireConnection()
        }
        let httpRequestOptions = try getHTTPRequestOptions(method: "GET", endpoint: host, path: getPath, semaphore: semaphore)
        let stream = try connection.makeRequest(requestOptions: httpRequestOptions)
        try stream.activate()
        semaphore.wait()
    }

    func testConnectionLivesUntilComplete() async throws {
        var stream: HTTPStream! = nil
        let semaphore = DispatchSemaphore(value: 0)

        do {
            let connectionManager = try await getHttpConnectionManager(endpoint: host, ssh: true, port: 443)
            let connection = try await connectionManager.acquireConnection()
            let httpRequestOptions = try getHTTPRequestOptions(method: "GET", endpoint: host, path: getPath, semaphore: semaphore)
            stream = try connection.makeRequest(requestOptions: httpRequestOptions)
        }
        try stream.activate()
        semaphore.wait()
    }

    func testConnectionCloseThrow() async throws {
        let connectionManager = try await getHttpConnectionManager(endpoint: host, ssh: true, port: 443)
        let connection = try await connectionManager.acquireConnection()
        connection.close()
        let httpRequestOptions = try getHTTPRequestOptions(method: "GET", endpoint: host, path: getPath)
        XCTAssertThrowsError( _ = try connection.makeRequest(requestOptions: httpRequestOptions))
    }

    func testConnectionCloseActivateThrow() async throws {
        let connectionManager = try await getHttpConnectionManager(endpoint: host, ssh: true, port: 443)
        let connection = try await connectionManager.acquireConnection()
        let httpRequestOptions = try getHTTPRequestOptions(method: "GET", endpoint: host, path: getPath)
        let stream = try connection.makeRequest(requestOptions: httpRequestOptions)
        connection.close()
        XCTAssertThrowsError(try stream.activate())
    }

    func testConnectionCloseIsIdempotent() async throws {
        let connectionManager = try await getHttpConnectionManager(endpoint: host, ssh: true, port: 443)
        let connection = try await connectionManager.acquireConnection()
        let httpRequestOptions = try getHTTPRequestOptions(method: "GET", endpoint: host, path: getPath)
        let stream = try connection.makeRequest(requestOptions: httpRequestOptions)
        connection.close()
        connection.close()
        connection.close()
        XCTAssertThrowsError(try stream.activate())
    }
}
