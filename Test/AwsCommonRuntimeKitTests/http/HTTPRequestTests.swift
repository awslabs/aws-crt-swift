//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
import AwsCCommon
@testable import AwsCommonRuntimeKit

class HTTPRequestTests: XCBaseTestCase {

    func testCreateHttpRequest() throws {
        let httpRequest = try HTTPRequest(method: "PUT", path: "testPath", allocator: allocator)
        XCTAssertEqual(httpRequest.method, "PUT")
        XCTAssertEqual(httpRequest.path, "testPath")

        httpRequest.method = "DELETE"
        httpRequest.path = "updatedPath"

        XCTAssertEqual(httpRequest.method, "DELETE")
        XCTAssertEqual(httpRequest.path, "updatedPath")
    }

    func testEmptyMethodAndPath() throws {
        let httpRequest = try HTTPRequest(method: "", path: "path", allocator: allocator)
        XCTAssertEqual(httpRequest.method, "")
        XCTAssertEqual(httpRequest.path, "path")

        httpRequest.method = "DELETE"
        httpRequest.path = ""

        XCTAssertEqual(httpRequest.method, "DELETE")
        XCTAssertEqual(httpRequest.path, "")
    }

    func testCreateHttpRequestWithHeaders() throws {
        let httpRequest = try HTTPRequest(headers: [HTTPHeader(name: "Name", value: "Value")], allocator: allocator)
        XCTAssertEqual(httpRequest.headerCount, 1)
    }

}
