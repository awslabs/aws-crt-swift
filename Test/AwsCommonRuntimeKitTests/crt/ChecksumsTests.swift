//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
import AwsCCommon
@testable import AwsCommonRuntimeKit

class ChecksumsTests: XCBaseTestCase {
    
    func testCRC32() throws {
        XCTAssertEqual("".data(using: .utf8)!.computeCRC32(), 0)
        XCTAssertEqual("Hello".data(using: .utf8)!.computeCRC32(), 4157704578)
        XCTAssertEqual("{\"foo\":\"base64 encoded sha1 checksum\"}".data(using: .utf8)!.computeCRC32(), 1195144130)
    }
    
    func testCRC32C() throws {
        XCTAssertEqual("".data(using: .utf8)!.computeCRC32C(), 0)
        XCTAssertEqual("Hello".data(using: .utf8)!.computeCRC32C(), 2178485787)
        XCTAssertEqual("{\"foo\":\"base64 encoded sha1 checksum\"}".data(using: .utf8)!.computeCRC32C(), 3565301023)
    }
    
}
