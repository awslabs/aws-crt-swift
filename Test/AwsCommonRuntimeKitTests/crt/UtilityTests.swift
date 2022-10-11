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

    func testSha256() throws {
        let hello = "Hello".data(using: .utf8)!
        let sha256 = ByteBuffer(data: hello).base64EncodedSha256()
        XCTAssertEqual(sha256, "GF+NsyJx/iX1Yab8k4suJkMG7DBO2lGAB9F2SCY4GWk=")
    }

    func testSha256_EmptyString() throws {
        let empty = "".data(using: .utf8)!
        let sha256 = ByteBuffer(data: empty).base64EncodedSha256()
        XCTAssertEqual(sha256, "47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=")
    }

    func testSha256_payload() throws {
        let payload = "{\"foo\":\"base64 encoded sha256 checksum\"}".data(using: .utf8)!
        let sha256 = ByteBuffer(data: payload).base64EncodedSha256()

        XCTAssertEqual(sha256, "lBSnDP4sj/yN8eIVOJlv+vC56hw+7JtN0132GiMQXRg=")
    }
}

