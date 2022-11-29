//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
import AwsCCommon
@testable import AwsCommonRuntimeKit

class HttpRequestTests: CrtXCBaseTestCase {

    func testCreateHttpRequest() throws {
        let httpRequest = try HttpRequest(method: "PUT", path: "testPath", allocator: allocator)
        XCTAssertEqual(try httpRequest.getMethod(), "PUT")
        XCTAssertEqual(try httpRequest.getPath(), "testPath")

        try httpRequest.setMethod(method: "DELETE")
        try httpRequest.setPath(path: "updatedPath")

        XCTAssertEqual(try httpRequest.getMethod(), "DELETE")
        XCTAssertEqual(try httpRequest.getPath(), "updatedPath")
    }


    func testCreateHttpRequestWithHeaders() throws {
        let httpHeaders = try HttpHeaders(allocator: allocator)
        XCTAssertTrue(httpHeaders.add(name: "Test", value: "Value"))

        let httpRequest = try HttpRequest(headers: httpHeaders, allocator: allocator)
        XCTAssertEqual(httpRequest.headerCount, 1)
        XCTAssertEqual(httpRequest.getHeader(atIndex: 0)?.value, "Value")
        XCTAssertNil(httpRequest.getHeader(atIndex: 1))

    }

}
