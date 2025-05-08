//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
import AwsCCommon

@testable import AwsCommonRuntimeKit

class ChecksumsTests: XCBaseTestCase {

  func testCRC32() throws {
    XCTAssertEqual("".data(using: .utf8)!.computeCRC32(), 0)
    XCTAssertEqual("Hello".data(using: .utf8)!.computeCRC32(), 4_157_704_578)
    XCTAssertEqual(
      "{\"foo\":\"base64 encoded sha1 checksum\"}".data(using: .utf8)!.computeCRC32(), 1_195_144_130
    )
  }

  func testCRC32C() throws {
    XCTAssertEqual("".data(using: .utf8)!.computeCRC32C(), 0)
    XCTAssertEqual("Hello".data(using: .utf8)!.computeCRC32C(), 2_178_485_787)
    XCTAssertEqual(
      "{\"foo\":\"base64 encoded sha1 checksum\"}".data(using: .utf8)!.computeCRC32C(),
      3_565_301_023)
  }

  func testCRC64Nvme() throws {
    XCTAssertEqual("".data(using: .utf8)!.computeCRC64Nvme(), 0)
    XCTAssertEqual(Data(count: 32).computeCRC64Nvme(), 0xCF34_7343_4D4E_CF3B)
    XCTAssertEqual(Data(Array(0..<32)).computeCRC64Nvme(), 0xB9D9_D4A8_492C_BD7F)
  }

}
