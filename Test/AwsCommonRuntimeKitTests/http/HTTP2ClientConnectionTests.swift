//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
@testable import AwsCommonRuntimeKit
import AwsCHttp

class HTTP2ClientConnectionTests: HTTPClientTestFixture {

    let expectedVersion = HTTPVersion.version_2
    let host = "httpbin.org"
    let sha256 = "C7FDB5314B9742467B16BD5EA2F8012190B5E2C44A005F7984F89AAB58219534"

    func testGetHTTP2RequestVersion() async throws {
        let connectionManager = try await getHttpConnectionManager(endpoint: host)
        try await sendHttpRequest(
                method: "GET",
                endpoint: host,
                path: "/get",
                expectedVersion: expectedVersion,
                connectionManager: connectionManager)

    }

    func testHTTP2Download() async throws {
        let connectionManager = try await getHttpConnectionManager(endpoint: "d1cz66xoahf9cl.cloudfront.net")
        let response = try await sendHttpRequest(
                method: "GET",
                endpoint: "d1cz66xoahf9cl.cloudfront.net",
                path: "/http_test_doc.txt",
                expectedVersion: expectedVersion,
                connectionManager: connectionManager)
        let actualSha = try response.body.data(using: .utf8)!.sha256()
        let base64 = actualSha.base64EncodedString()
        XCTAssertEqual(String(data: actualSha, encoding: .utf8)!, "C7FDB5314B9742467B16BD5EA2F8012190B5E2C44A005F7984F89AAB58219534")

    }

}
