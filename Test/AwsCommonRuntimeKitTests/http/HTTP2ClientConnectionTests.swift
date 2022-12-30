//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
@testable import AwsCommonRuntimeKit
import AwsCHttp

class HTTP2ClientConnectionTests: HTTPClientTestFixture {

    let expectedVersion = HTTPVersion.version_2

    func testGetHTTP2RequestVersion() async throws {
        let connectionManager = try await getHttpConnectionManager(endpoint: "httpbin.org")
        _ = try await sendHttpRequest(
                method: "GET",
                endpoint: "httpbin.org",
                path: "/get",
                expectedVersion: expectedVersion,
                connectionManager: connectionManager)

    }

    func testHTTP2UpdateSetting() async throws {
        let connectionManager = try await getHttpConnectionManager(endpoint: "httpbin.org")
        let connection = try await sendHttpRequest(
                method: "GET",
                endpoint: "httpbin.org",
                path: "/get",
                expectedVersion: expectedVersion,
                connectionManager: connectionManager)
        if connection is HTTP2ClientConnection {

        } else {
            XCTFail("Connection is not HTTP2")
        }
    }

    func testGetHttpsRequest() async throws {
        let connectionManager = try await getHttpConnectionManager(endpoint: "httpbin.org")

        _ = try await sendHttpRequest(method: "GET", endpoint: "httpbin.org", path: "/get", expectedVersion: expectedVersion,
                connectionManager: connectionManager)
        _ = try await sendHttpRequest(method: "GET", endpoint: "httpbin.org", path: "/delete", expectedStatus: 405,expectedVersion: expectedVersion,
                connectionManager: connectionManager)
    }

    //TODO: fix cleartext http2 request
//    func testGetHttpRequest() async throws {
//        do {
//        let connectionManager = try await getHttpConnectionManager(endpoint: "httpbin.org", ssh: false, port: 80, http2PriorKnowledge: true)
//        _ = try await sendHttpRequest(method: "GET", endpoint: "httpbin.org", path: "/get", expectedVersion: expectedVersion,
//                connectionManager: connectionManager)
//        } catch CommonRunTimeError.crtError(let error) {
//            print(error)
//            XCTFail(error.message)
//        }
//    }


    func testHTTP2Download() async throws {
        let connectionManager = try await getHttpConnectionManager(endpoint: "d1cz66xoahf9cl.cloudfront.net")
        let response = try await sendHttpRequest(
                method: "GET",
                endpoint: "d1cz66xoahf9cl.cloudfront.net",
                path: "/http_test_doc.txt",
                expectedVersion: expectedVersion,
                connectionManager: connectionManager)
        let actualSha = try response.body.data(using: .utf8)!.sha256()
        XCTAssertEqual(
                actualSha.encodeToHexString().uppercased(),
                "C7FDB5314B9742467B16BD5EA2F8012190B5E2C44A005F7984F89AAB58219534")

    }

}
