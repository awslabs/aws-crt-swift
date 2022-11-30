//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit

class HttpMessageTests: CrtXCBaseTestCase {

    func testAddHttpHeaders() throws {
        let httpMessage = try HttpMessage(allocator: allocator)
        try httpMessage.addHeaders(headers: [
            HttpHeader(name: "header1", value: "value1"),
            HttpHeader(name: "header2", value: "value2")])
        XCTAssertEqual(httpMessage.headerCount, 2)
    }

    func testGetHeaders() throws {
        let headers = [
            HttpHeader(name: "header1", value: "value1"),
            HttpHeader(name: "header2", value: "value2")]
        let httpMessage = try HttpMessage(allocator: allocator)
        try httpMessage.addHeaders(headers: headers)
        let requestHeaders = httpMessage.getHeaders()
        XCTAssertTrue(headers.elementsEqual(requestHeaders, by: { $0.name == $1.name && $0.value == $1.value}))
    }

    func testGetHttpHeader() throws {
        let headers = [
            HttpHeader(name: "header1", value: "value1"),
            HttpHeader(name: "header2", value: "value2")]
        let httpMessage = try HttpMessage(allocator: allocator)
        try httpMessage.addHeaders(headers: headers)

        let header = httpMessage.getHeader(atIndex: 0)
        XCTAssertEqual(header.name, "header1")
        XCTAssertEqual(header.value, "value1")

        let header2 = httpMessage.getHeader(atIndex: 1)
        XCTAssertEqual(header2.name, "header2")
        XCTAssertEqual(header2.value, "value2")
    }

    func testRemoveHttpHeaders() throws {
        let headers = [
            HttpHeader(name: "header1", value: "value1"),
            HttpHeader(name: "header2", value: "value2")]
        let httpMessage = try HttpMessage(allocator: allocator)
        try httpMessage.addHeaders(headers: headers)
        XCTAssertEqual(httpMessage.headerCount, 2)
        try httpMessage.addHeader(header: HttpHeader(name: "HeaderToRemove", value: "xyz"))
        try httpMessage.removeHeader(atIndex: 2)
        let allHeaders = httpMessage.getHeaders()

        XCTAssertFalse(allHeaders.contains { (header) -> Bool in
            header.name == "HeaderToRemove"
        })
    }

}
