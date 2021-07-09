//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit

class HttpHeaderTests: CrtXCBaseTestCase {
    
    var httpHeaders: HttpHeaders?
    
    override func setUp() {
        super.setUp()
        httpHeaders = HttpHeaders(allocator: allocator)
        let headerAdded = httpHeaders?.add(name: "Test", value: "Value")
        XCTAssertTrue(headerAdded!)
    }
    
    override func tearDown() {
        httpHeaders = nil
    }
    
    func testCreateHttpHeaders() {
        _ = HttpHeaders(allocator: allocator)
    }
    
    func testGetAllHttpHeaders() {
        let allHeaders = httpHeaders?.getAll()
        XCTAssertEqual(allHeaders!.count, 1)
        
    }
    
    func testGetHttpHeaders() {
        let getHeader = httpHeaders?.get(name: "Test")
        XCTAssertNotNil(getHeader)
        XCTAssertEqual(getHeader!, "Value")
    }
    
    func testDeleteHttpHeaders() {
        let headerAdded = httpHeaders?.add(name: "HeaderToRemove", value: "LoseMe")
        XCTAssertTrue(headerAdded!)
        let headerRemoved = httpHeaders?.remove(name: "HeaderToRemove")
        XCTAssertTrue(headerRemoved!)
        let allHeaders = httpHeaders?.getAll()
        
        let nopeNotHere = allHeaders!.contains { (header) -> Bool in
            header.name == "HeaderToRemove"
        }
        XCTAssertFalse(nopeNotHere)
    }
    
    func testDeleteAllHttpHeaders() {
        httpHeaders?.removeAll()
        
        XCTAssertEqual(httpHeaders?.count, 0)
    }
    
    func testAddArrayOfHttpHeaders() {
        var headersToAdd = [HttpHeader]()
        let header = HttpHeader(name: "AddMe", value: "Please")
        let header1 = HttpHeader(name: "DontForget", value: "AboutMe")
        let header2 = HttpHeader(name: "How", value: "CouldI")
        headersToAdd = [header, header1, header2]
        
        httpHeaders?.addArray(headers: headersToAdd)
        XCTAssertEqual(httpHeaders?.count, 4)
    }
}
