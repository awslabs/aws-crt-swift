//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
@testable import AwsCommonRuntimeKit
import AwsCHttp

class HTTP2ClientConnectionTests: HTTPClientTestFixture {

    let expectedVersion = HTTPVersion.version_2
    let host = "https://httpbin.org"

    func testGetHttpRequest() async throws {
        try await sendHttpRequest(
                method: "GET",
                endpoint: "httpbin.org",
                path: "/get",
                expectedVersion: expectedVersion)
    }
}
