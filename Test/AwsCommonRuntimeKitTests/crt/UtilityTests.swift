//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
import AwsCCommon
@testable import AwsCommonRuntimeKit

class UtilityTests: XCBaseTestCase {

    func testMd5() throws {
        let hello = "Hello"
        let md5 = try hello.base64EncodedMD5(allocator: allocator)
        XCTAssertEqual(md5, "ixqZU8RhEpaoJ6v4xHgE1w==")
    }

    func testMd5Payload() throws {
        let payload = "{\"foo\":\"base64 encoded md5 checksum\"}"

        let md5 = try payload.base64EncodedMD5(allocator: allocator)

        XCTAssertEqual(md5, "iB0/3YSo7maijL0IGOgA9g==")
    }

    func testSha256() throws {
        let hello = "Hello".data(using: .utf8)!
        let sha256 = try! hello.sha256().base64EncodedString()
        XCTAssertEqual(sha256, "GF+NsyJx/iX1Yab8k4suJkMG7DBO2lGAB9F2SCY4GWk=")
    }

    func testSha256EmptyString() throws {
        let empty = "".data(using: .utf8)!
        let sha256 = try! empty.sha256().base64EncodedString()
        XCTAssertEqual(sha256, "47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=")
    }

    func testSha256PayloadOutOfScope() throws {
        var sha256Data: Data! = nil
        do {
            let payload = "{\"foo\":\"base64 encoded sha256 checksum\"}".data(using: .utf8)!
            sha256Data = try! payload.sha256()
        }
        XCTAssertEqual(sha256Data.base64EncodedString(), "lBSnDP4sj/yN8eIVOJlv+vC56hw+7JtN0132GiMQXRg=")
    }

    func testByteCursorListToStringArray() throws {
        let list: UnsafeMutablePointer<aws_array_list> = allocator.allocate(capacity: 1)
        defer {
            aws_array_list_clean_up(list)
            allocator.release(list)
        }
        let init_size: size_t  = 4

        "first".withByteCursorPointer { firstCursorPointer in
            aws_array_list_init_dynamic(list, allocator.rawValue, init_size, MemoryLayout.size(ofValue: firstCursorPointer.pointee))
            XCTAssertEqual(0, list.pointee.length)
            aws_array_list_push_front(list, firstCursorPointer)
            XCTAssertEqual(1, list.pointee.length)

            "second".withByteCursorPointer { secondCursorPointer in
                aws_array_list_push_front(list, secondCursorPointer)
                XCTAssertEqual(2, aws_array_list_length(list))

                "third".withByteCursorPointer { thirdCursorPointer in
                    aws_array_list_push_front(list, thirdCursorPointer)
                    XCTAssertEqual(3, list.pointee.length)

                    let result = list.pointee.byteCursorListToStringArray()
                    XCTAssertEqual(result, ["third", "second", "first"])
                }
            }
        }
    }

}

