////  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
////  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit

class HTTP2ClientConnectionTests: HTTPClientTestFixture {

    let expectedVersion = HTTPVersion.version_2

    func testGetHTTP2RequestVersion() async throws {
        let connectionManager = try await getHttpConnectionManager(endpoint: "httpbin.org", alpnList: ["h2","http/1.1"])
        let connection = try await connectionManager.acquireConnection()
        XCTAssertEqual(connection.httpVersion, HTTPVersion.version_2)
    }

    // Test that the binding works not the actual functionality. C part has tests for functionality
    func testHTTP2UpdateSetting() async throws {
        let connectionManager = try await getHttpConnectionManager(endpoint: "httpbin.org", alpnList: ["h2","http/1.1"])
        let connection = try await connectionManager.acquireConnection()
        if let connection = connection as? HTTP2ClientConnection {
            try await connection.updateSetting(setting: HTTP2Settings(enablePush: false))
        } else {
            XCTFail("Connection is not HTTP2")
        }
    }

    // Test that the binding works not the actual functionality. C part has tests for functionality
    func testHTTP2UpdateSettingEmpty() async throws {
        let connectionManager = try await getHttpConnectionManager(endpoint: "httpbin.org", alpnList: ["h2","http/1.1"])
        let connection = try await connectionManager.acquireConnection()
        if let connection = connection as? HTTP2ClientConnection {
            try await connection.updateSetting(setting: HTTP2Settings())
        } else {
            XCTFail("Connection is not HTTP2")
        }
    }

    // Test that the binding works not the actual functionality. C part has tests for functionality
    func testHTTP2SendPing() async throws {
        let connectionManager = try await getHttpConnectionManager(endpoint: "httpbin.org", alpnList: ["h2","http/1.1"])
        let connection = try await connectionManager.acquireConnection()
        if let connection = connection as? HTTP2ClientConnection {
            var time = try await connection.sendPing()
            XCTAssertTrue(time > 0)
            time = try await connection.sendPing(data: "12345678".data(using: .utf8)!)
            XCTAssertTrue(time > 0)
        } else {
            XCTFail("Connection is not HTTP2")
        }
    }

    // Test that the binding works not the actual functionality. C part has tests for functionality
    func testHTTP2SendGoAway() async throws {
        let connectionManager = try await getHttpConnectionManager(endpoint: "httpbin.org", alpnList: ["h2","http/1.1"])
        let connection = try await connectionManager.acquireConnection()
        if let connection = connection as? HTTP2ClientConnection {
          connection.sendGoAway(error: .internalError, allowMoreStreams: false)
        } else {
            XCTFail("Connection is not HTTP2")
        }
    }

    func testGetHttpsRequest() async throws {
        let connectionManager = try await getHttpConnectionManager(endpoint: "httpbin.org", alpnList: ["h2","http/1.1"])
        let response = try await sendHTTPRequest(
                method: "GET",
                endpoint: "httpbin.org",
                path: "/get",
                connectionManager: connectionManager,
                expectedVersion: expectedVersion,
                requestVersion: .version_2)
        // The first header of response has to be ":status" for HTTP/2 response
        XCTAssertEqual(response.headers[0].name, ":status")
        let response2 = try await sendHTTPRequest(
                method: "GET",
                endpoint: "httpbin.org",
                path: "/delete",
                expectedStatus: 405,
                connectionManager: connectionManager,
                expectedVersion: expectedVersion,
                requestVersion: .version_2)
        XCTAssertEqual(response2.headers[0].name, ":status")
    }


    func testGetHttpsRequestWithHTTP1_1Request() async throws {
        let connectionManager = try await getHttpConnectionManager(endpoint: "httpbin.org", alpnList: ["h2","http/1.1"])
        let response = try await sendHTTPRequest(
                method: "GET",
                endpoint: "httpbin.org",
                path: "/get",
                connectionManager: connectionManager,
                expectedVersion: expectedVersion,
                requestVersion: .version_1_1)
        // The first header of response has to be ":status" for HTTP/2 response
        XCTAssertEqual(response.headers[0].name, ":status")
        let response2 = try await sendHTTPRequest(
                method: "GET",
                endpoint: "httpbin.org",
                path: "/delete",
                expectedStatus: 405,
                connectionManager: connectionManager,
                expectedVersion: expectedVersion,
                requestVersion: .version_1_1)
        XCTAssertEqual(response2.headers[0].name, ":status")
    }

    func testHTTP2Download() async throws {
        let connectionManager = try await getHttpConnectionManager(endpoint: "d1cz66xoahf9cl.cloudfront.net", alpnList: ["h2","http/1.1"])
        let response = try await sendHTTPRequest(
                method: "GET",
                endpoint: "d1cz66xoahf9cl.cloudfront.net",
                path: "/http_test_doc.txt",
                connectionManager: connectionManager,
                expectedVersion: expectedVersion,
                requestVersion: .version_2)
        let actualSha = try response.body.computeSHA256()
        XCTAssertEqual(
                actualSha.encodeToHexString().uppercased(),
                "C7FDB5314B9742467B16BD5EA2F8012190B5E2C44A005F7984F89AAB58219534")
    }

    func testHTTP2DownloadWithHTTP1_1Request() async throws {
        let connectionManager = try await getHttpConnectionManager(endpoint: "d1cz66xoahf9cl.cloudfront.net", alpnList: ["h2","http/1.1"])
        let response = try await sendHTTPRequest(
                method: "GET",
                endpoint: "d1cz66xoahf9cl.cloudfront.net",
                path: "/http_test_doc.txt",
                connectionManager: connectionManager,
                expectedVersion: expectedVersion,
                requestVersion: .version_1_1)
        let actualSha = try response.body.computeSHA256()
        XCTAssertEqual(
                actualSha.encodeToHexString().uppercased(),
                "C7FDB5314B9742467B16BD5EA2F8012190B5E2C44A005F7984F89AAB58219534")
    }

    func testHTTP2StreamUpload() async throws {
        let connectionManager = try await getHttpConnectionManager(endpoint: "nghttp2.org", alpnList: ["h2"])
        let semaphore = DispatchSemaphore(value: 0)
        var httpResponse = HTTPResponse()
        var onCompleteCalled = false
        let testBody = "testBody"
        let http2RequestOptions = try getHTTP2RequestOptions(
                method: "PUT",
                path: "/httpbin/put",
                authority: "nghttp2.org",
                body: testBody,
                response: &httpResponse,
                semaphore: semaphore,
                onComplete: { _ in
                    onCompleteCalled = true
                },
                http2ManualDataWrites: true)
        let connection = try await connectionManager.acquireConnection()
        let streamBase = try connection.makeRequest(requestOptions: http2RequestOptions)
        try streamBase.activate()
        XCTAssertFalse(onCompleteCalled)
        let data = TEST_DOC_LINE.data(using: .utf8)!
        for chunk in data.chunked(into: 5) {
            try await streamBase.writeChunk(chunk: chunk, endOfStream: false)
            XCTAssertFalse(onCompleteCalled)
        }

        XCTAssertFalse(onCompleteCalled)
        // Sleep for 5 seconds to make sure onComplete is not triggerred until endOfStream is true
        try await Task.sleep(nanoseconds: 5_000_000_000)
        XCTAssertFalse(onCompleteCalled)
        try await streamBase.writeChunk(chunk: Data(), endOfStream: true)
        semaphore.wait()
        XCTAssertTrue(onCompleteCalled)
        XCTAssertNil(httpResponse.error)
        XCTAssertEqual(httpResponse.statusCode, 200)

        // Parse json body
        struct Response: Codable {
            let data: String
        }

        let body: Response = try! JSONDecoder().decode(Response.self, from: httpResponse.body)
        XCTAssertEqual(body.data, testBody + TEST_DOC_LINE)
    }
}
