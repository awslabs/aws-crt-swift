//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
import AwsCCommon

@testable import AwsCommonRuntimeKit

class HashTests: XCBaseTestCase {

  func testMd5() throws {
    let hello = "Hello"
    let md5 = try hello.data(using: .utf8)!.computeMD5().base64EncodedString()
    XCTAssertEqual(md5, "ixqZU8RhEpaoJ6v4xHgE1w==")
  }

  func testMd5Payload() throws {
    let payload = "{\"foo\":\"base64 encoded md5 checksum\"}"

    let md5 = try payload.data(using: .utf8)!.computeMD5().base64EncodedString()

    XCTAssertEqual(md5, "iB0/3YSo7maijL0IGOgA9g==")
  }

  func testMd5PayloadWithUpdate() throws {
    let hello = "Hello".data(using: .utf8)!
    let world = "World".data(using: .utf8)!

    let helloWorld = "HelloWorld".data(using: .utf8)!
    let md5 = try! helloWorld.computeMD5().encodeToHexString()

    let hash = Hash(algorithm: .MD5)
    try hash.update(data: hello)
    try hash.update(data: world)
    let finalizedHash = try hash.finalize().encodeToHexString()

    XCTAssertEqual(md5, finalizedHash)
    XCTAssertEqual(finalizedHash, "68e109f0f40ca72a15e05cc22786f8e6")
  }

  func testSha256() throws {
    let hello = "Hello".data(using: .utf8)!
    let sha256 = try! hello.computeSHA256().base64EncodedString()
    XCTAssertEqual(sha256, "GF+NsyJx/iX1Yab8k4suJkMG7DBO2lGAB9F2SCY4GWk=")
  }

  func testSha256WithUpdate() throws {
    let hello = "Hello".data(using: .utf8)!
    let world = "World".data(using: .utf8)!

    let helloWorld = "HelloWorld".data(using: .utf8)!
    let sha256 = try! helloWorld.computeSHA256().encodeToHexString()

    let hash = Hash(algorithm: .SHA256)
    try hash.update(data: hello)
    try hash.update(data: world)
    let finalizedHash = try hash.finalize().encodeToHexString()

    XCTAssertEqual(sha256, finalizedHash)
    XCTAssertEqual(
      finalizedHash, "872e4e50ce9990d8b041330c47c9ddd11bec6b503ae9386a99da8584e9bb12c4")
  }

  func testSha256EmptyString() throws {
    let empty = "".data(using: .utf8)!
    let sha256 = try! empty.computeSHA256().base64EncodedString()
    XCTAssertEqual(sha256, "47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=")
  }

  func testSha256PayloadOutOfScope() throws {
    var sha256Data: Data! = nil
    do {
      let payload = "{\"foo\":\"base64 encoded sha256 checksum\"}".data(using: .utf8)!
      sha256Data = try! payload.computeSHA256()
    }
    XCTAssertEqual(sha256Data.base64EncodedString(), "lBSnDP4sj/yN8eIVOJlv+vC56hw+7JtN0132GiMQXRg=")
  }

  func testSha1() throws {
    let hello = "Hello".data(using: .utf8)!
    XCTAssertEqual(
      try! hello.computeSHA1().encodeToHexString(), "f7ff9e8b7bb2e09b70935a5d785e0cc5d9d0abf0")
  }

  func testSha1WithUpdate() throws {
    let hello = "Hello".data(using: .utf8)!
    let world = "World".data(using: .utf8)!

    let helloWorld = "HelloWorld".data(using: .utf8)!
    let sha1 = try! helloWorld.computeSHA1().encodeToHexString()

    let hash = Hash(algorithm: .SHA1)
    try hash.update(data: hello)
    try hash.update(data: world)
    let finalizedHash = try hash.finalize().encodeToHexString()

    XCTAssertEqual(sha1, finalizedHash)
    XCTAssertEqual(finalizedHash, "db8ac1c259eb89d4a131b253bacfca5f319d54f2")
  }

  func testSha1EmptyString() throws {
    let empty = "".data(using: .utf8)!
    XCTAssertEqual(
      try! empty.computeSHA1().encodeToHexString(), "da39a3ee5e6b4b0d3255bfef95601890afd80709")
  }

  func testSha1PayloadOutOfScope() throws {
    var sha1Data: Data! = nil
    do {
      let payload = "{\"foo\":\"base64 encoded sha1 checksum\"}".data(using: .utf8)!
      sha1Data = try! payload.computeSHA1()
    }
    XCTAssertEqual(sha1Data.encodeToHexString(), "bc3c579755c719da780d4429d6e9cf32f0c29c7e")
  }

  func testByteCursorListToStringArray() throws {
    let list: UnsafeMutablePointer<aws_array_list> = allocator.allocate(capacity: 1)
    defer {
      aws_array_list_clean_up(list)
      allocator.release(list)
    }
    let init_size: size_t = 4

    "first".withByteCursorPointer { firstCursorPointer in
      aws_array_list_init_dynamic(
        list, allocator.rawValue, init_size, MemoryLayout.size(ofValue: firstCursorPointer.pointee))
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
