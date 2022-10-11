//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
import AwsCCommon
@testable import AwsCommonRuntimeKit

class HttpRequestTests: CrtXCBaseTestCase {

    func testCreateHttpRequest() throws {
        let httpRequest = try HttpRequest(allocator: allocator)
        XCTAssertNotNil(httpRequest.rawValue)
        XCTAssertNil(httpRequest.method)
        XCTAssertNil(httpRequest.path)

        httpRequest.method = "Get"
        httpRequest.path = "test"

        XCTAssertNotNil(httpRequest.method)
        XCTAssertNotNil(httpRequest.path)
    }


    func testCreateHttpRequestWithHeaders() throws {
        let httpHeaders = try HttpHeaders(allocator: allocator)
        XCTAssertTrue(httpHeaders.add(name: "Test", value: "Value"))

        let httpRequest = try HttpRequest(allocator: allocator, headers: httpHeaders)
        XCTAssertEqual(httpRequest.headerCount, 1)
        XCTAssertEqual(httpRequest.getHeader(atIndex: 0)?.value, "Value")
        XCTAssertNil(httpRequest.getHeader(atIndex: 1))

    }

}
