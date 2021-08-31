//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
#if os(Linux)
     import Glibc
 #else
     import Darwin
 #endif
@testable import AwsCommonRuntimeKit

class UtilityTests: XCTestCase {
    func testMd5() throws {
        let hello = "Hello"
        let md5 = hello.base64EncodedMD5()
        XCTAssertEqual(md5, "ixqZU8RhEpaoJ6v4xHgE1w==")
    }
    
    func testMd5_payload() throws {
        let payload = "{\"foo\":\"base64 encoded md5 checksum\"}"

        let md5 = payload.base64EncodedMD5()
        
        XCTAssertEqual(md5, "iB0/3YSo7maijL0IGOgA9g==")
    }
}

