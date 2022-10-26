//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit

class HttpMessageTests: CrtXCBaseTestCase {

    var httpMessage: HttpMessage?

    override func setUp() {
        super.setUp()
        httpMessage = try? HttpMessage(allocator: allocator)
        let httpHeaders = try? HttpHeaders(allocator: allocator)
        let headerAdded = httpHeaders?.add(name: "Test", value: "Value")
        XCTAssertTrue(headerAdded!)
        httpMessage?.addHeaders(headers: httpHeaders!)
    }

    override func tearDown() {
        httpMessage = nil
    }

    func testCreateHttpMessage() throws {
        _ = try HttpMessage(allocator: allocator)
    }

    func testAddHttpHeaders() throws {
        let httpHeaders = try HttpHeaders(allocator: allocator)
        let headerAdded = httpHeaders.add(name: "Test2", value: "Value2")
        XCTAssertTrue(headerAdded)
        httpMessage?.addHeaders(headers: httpHeaders)
        XCTAssertEqual(httpMessage?.headerCount, 2)
    }

    func testGetAllHttpHeaders() throws {
        var allHeaders = httpMessage?.getHeaders()
        XCTAssertEqual(allHeaders!.count, 1)

        let httpHeaders = try HttpHeaders(allocator: allocator)
        let headerAdded = httpHeaders.add(name: "Test2", value: "Value2")
        XCTAssertTrue(headerAdded)
        httpMessage?.addHeaders(headers: httpHeaders)

        allHeaders = httpMessage?.getHeaders()
        XCTAssertEqual(allHeaders!.count, 2)
    }

    func testGetHttpHeaders() {
        let getHeader = httpMessage?.getHeader(atIndex: 0)
        XCTAssertNotNil(getHeader)
        XCTAssertEqual(getHeader?.value, "Value")

        let nilHeader = httpMessage?.getHeader(atIndex: 1)
        XCTAssertNil(nilHeader)
    }

    func testRemoveHttpHeaders() {
        let httpHeaders = try? HttpHeaders(allocator: allocator)
        let headerAdded = httpHeaders?.add(name: "HeaderToRemove", value: "LoseMe")
        XCTAssertTrue(headerAdded!)
        httpMessage?.addHeaders(headers: httpHeaders!)
        XCTAssertEqual(httpMessage?.headerCount, 2)

        let headerRemoved = httpMessage?.removeHeader(atIndex: 1)
        XCTAssertTrue(headerRemoved!)
        let allHeaders = httpMessage?.getHeaders()

        let nopeNotHere = allHeaders!.contains { (header) -> Bool in
            header.name == "HeaderToRemove"
        }
        XCTAssertFalse(nopeNotHere)
    }

}
