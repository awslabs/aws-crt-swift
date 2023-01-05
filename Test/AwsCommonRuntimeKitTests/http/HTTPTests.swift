//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
@testable import AwsCommonRuntimeKit
import AwsCCommon
import AwsCHttp

class HTTPTests: HTTPClientTestFixture {
    let host = "httpbin.org"
    let getPath = "/get"
    let TEST_DOC_LINE: String = """
                                This is a sample to prove that http downloads and uploads work. 
                                It doesn't really matter what's in here, 
                                we mainly just need to verify the downloads and uploads work.
                                """

    func testGetHTTPSRequest() async throws {
        let connectionManager = try await getHttpConnectionManager(endpoint: host, ssh: true, port: 443)
        _ = try await sendHttpRequest(method: "GET", endpoint: host, path: getPath, connectionManager: connectionManager)
        _ = try await sendHttpRequest(method: "GET", endpoint: host, path: "/delete", expectedStatus: 405, connectionManager: connectionManager)
    }

    func testGetHTTPRequest() async throws {
        let connectionManager = try await getHttpConnectionManager(endpoint: host, ssh: false, port: 80)
        _ = try await sendHttpRequest(method: "GET", endpoint: host, path: getPath, connectionManager: connectionManager)
    }

    func testPutHttpRequest() async throws {
        let connectionManager = try await getHttpConnectionManager(endpoint: host, ssh: true, port: 443)
        let response = try await sendHttpRequest(
                method: "PUT",
                endpoint: host,
                path: "/anything",
                requestBody: TEST_DOC_LINE,
                connectionManager: connectionManager)

        // Parse json body
        struct Response: Codable {
            let data: String
        }
        let body: Response = try! JSONDecoder().decode(Response.self, from: response.body)
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
        do {
            let httpRequestOptions = try getHTTPRequestOptions(method: "GET", endpoint: host, path: getPath)
            let connectionManager = try await getHttpConnectionManager(endpoint: host, ssh: true, port: 443)
            let connection = try await connectionManager.acquireConnection()
            let stream = try connection.makeRequest(requestOptions: httpRequestOptions)
            try stream.activate()
        }
        semaphore.wait()
    }

    func testManagerLivesUntilComplete() async throws {
        var connection: HTTPExchange! = nil
        do {
            let connectionManager = try await getHttpConnectionManager(endpoint: host, ssh: true, port: 443)
            connection = try await connectionManager.acquireConnection()
        }
        let httpRequestOptions = try getHTTPRequestOptions(method: "GET", endpoint: host, path: getPath)
        let stream = try connection.makeRequest(requestOptions: httpRequestOptions)
        try stream.activate()
        semaphore.wait()
    }

    func testConnectionLivesUntilComplete() async throws {
        var stream: HTTPStream! = nil
        do {
            let connectionManager = try await getHttpConnectionManager(endpoint: host, ssh: true, port: 443)
            let connection = try await connectionManager.acquireConnection()
            let httpRequestOptions = try getHTTPRequestOptions(method: "GET", endpoint: host, path: getPath)
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
