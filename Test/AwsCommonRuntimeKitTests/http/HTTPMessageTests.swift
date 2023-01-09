//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit
import AwsCHttp

class HTTPMessageTests: XCBaseTestCase {
    func testAddHeaders() throws {
        let httpMessage = HTTPRequestBase(
                rawValue: aws_http_message_new_request(allocator.rawValue)!,
                allocator: allocator)
        httpMessage.addHeaders(headers: [
            HTTPHeader(name: "header1", value: "value1"),
            HTTPHeader(name: "header2", value: "value2")])
        XCTAssertEqual(httpMessage.headerCount, 2)
    }

    func testGetHeaders() throws {
        let headers = [
            HTTPHeader(name: "header1", value: "value1"),
            HTTPHeader(name: "header2", value: "value2")]
        let httpMessage = HTTPRequestBase(
                rawValue: aws_http_message_new_request(allocator.rawValue)!,
                allocator: allocator)
        httpMessage.addHeaders(headers: headers)
        let requestHeaders = httpMessage.getHeaders()
        XCTAssertTrue(headers.elementsEqual(requestHeaders, by: { $0.name == $1.name && $0.value == $1.value}))
    }

    func testGetHeader() throws {
        let headers = [
            HTTPHeader(name: "header1", value: "value1"),
            HTTPHeader(name: "header2", value: "value2")]
        let httpMessage = HTTPRequestBase(
                rawValue: aws_http_message_new_request(allocator.rawValue)!,
                allocator: allocator)
        httpMessage.addHeaders(headers: headers)

        XCTAssertEqual(httpMessage.getHeaderValue(name: "header1"), "value1")
        XCTAssertEqual(httpMessage.getHeaderValue(name: "header2"), "value2")
        XCTAssertNil(httpMessage.getHeaderValue(name: "invalidHeaderName"))
    }

    func testRemoveHeader() throws {
        let headers = [
            HTTPHeader(name: "header1", value: "value1"),
            HTTPHeader(name: "header2", value: "value2")]
        let httpMessage = HTTPRequestBase(
                rawValue: aws_http_message_new_request(allocator.rawValue)!,
                allocator: allocator)
        httpMessage.addHeaders(headers: headers)
        XCTAssertEqual(httpMessage.headerCount, 2)
        httpMessage.addHeader(header: HTTPHeader(name: "HeaderToRemove", value: "xyz"))
        httpMessage.removeHeader(name: "HeaderToRemove")
        httpMessage.removeHeader(name: "Doesn't Exit")
        let allHeaders = httpMessage.getHeaders()
        XCTAssertTrue(headers.elementsEqual(allHeaders, by: { $0.name == $1.name && $0.value == $1.value}))
    }

    func testAddEmptyHeader() throws {
        let headers = [
            HTTPHeader(name: "header1", value: "value1"),
            HTTPHeader(name: "header2", value: "value2")]
        let httpMessage = HTTPRequestBase(
                rawValue: aws_http_message_new_request(allocator.rawValue)!,
                allocator: allocator)
        httpMessage.addHeaders(headers: headers)
        XCTAssertEqual(httpMessage.headerCount, 2)
        httpMessage.addHeader(header: HTTPHeader(name: "", value: "xyz"))
        XCTAssertEqual(httpMessage.headerCount, 2)
    }

    func testClearHeaders() throws {
        let headers = [
            HTTPHeader(name: "header1", value: "value1"),
            HTTPHeader(name: "header2", value: "value2")]
        let httpMessage = HTTPRequestBase(
                rawValue: aws_http_message_new_request(allocator.rawValue)!,
                allocator: allocator)
        httpMessage.addHeaders(headers: headers)
        XCTAssertEqual(httpMessage.headerCount, 2)
        httpMessage.clearHeaders()
        XCTAssertEqual(httpMessage.headerCount, 0)
        XCTAssertTrue(httpMessage.getHeaders().isEmpty)
    }

    func testSetHeader() throws {
        let headers = [
            HTTPHeader(name: "header1", value: "value1"),
            HTTPHeader(name: "header2", value: "value2")]
        let httpMessage = HTTPRequestBase(
                rawValue: aws_http_message_new_request(allocator.rawValue)!,
                allocator: allocator)
        httpMessage.addHeaders(headers: headers)
        XCTAssertEqual(httpMessage.headerCount, 2)

        httpMessage.setHeader(name: "header1", value: "newValue")
        XCTAssertEqual(httpMessage.getHeaderValue(name: "header1"), "newValue")
        httpMessage.setHeader(name: "header3", value: "value3")
        httpMessage.setHeader(name: "", value: "value4")
        XCTAssertEqual(httpMessage.headerCount, 3)
        XCTAssertEqual(httpMessage.getHeaderValue(name: "header3"), "value3")
    }

}
