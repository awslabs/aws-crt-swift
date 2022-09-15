//
//  File.swift
//  
//
//  Created by Khan, Waqar Ahmed on 9/13/22.
//

import XCTest
@testable import AwsCommonRuntimeKit

class HttpTests: CrtXCBaseTestCase {
    
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
}
