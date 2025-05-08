import Foundation
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest

@testable import AwsCommonRuntimeKit

class StreamTests: XCBaseTestCase {

  func testByteBufferStream() throws {
    let byteBuffer = ByteBuffer(data: "12345678900987654321".data(using: .utf8)!)
    let iStreamCore = IStreamCore(iStreamable: byteBuffer)
    try testStream(iStreamCore: iStreamCore)
  }

  func testByteBufferEndOfStream() throws {
    let data = "1234567890098765432112345678900987654321".data(using: .utf8)!
    let byteBuffer = ByteBuffer(data: data[20...])
    let iStreamCore = IStreamCore(iStreamable: byteBuffer)
    try testStream(iStreamCore: iStreamCore)
  }

  func testStream(iStreamCore: IStreamCore) throws {

    let capacity = 10
    let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: capacity)
    defer {
      buffer.deallocate()
    }

    XCTAssertEqual(20, try iStreamCore.iStreamable.length())
    XCTAssertFalse(iStreamCore.iStreamable.isEndOfStream())

    var length = try iStreamCore.iStreamable.read(buffer: buffer)
    XCTAssertEqual(length, capacity)
    XCTAssertEqual(String(bytes: buffer, encoding: .utf8), "1234567890")
    XCTAssertFalse(iStreamCore.iStreamable.isEndOfStream())

    length = try iStreamCore.iStreamable.read(buffer: buffer)
    XCTAssertEqual(length, capacity)
    XCTAssertEqual(String(bytes: buffer, encoding: .utf8), "0987654321")
    XCTAssertTrue(iStreamCore.iStreamable.isEndOfStream())

    length = try iStreamCore.iStreamable.read(buffer: buffer)
    XCTAssertEqual(length, nil)

    try iStreamCore.iStreamable.seek(offset: 0, streamSeekType: StreamSeekType.begin)
    XCTAssertFalse(iStreamCore.iStreamable.isEndOfStream())
    length = try iStreamCore.iStreamable.read(buffer: buffer)
    XCTAssertEqual(length, capacity)
    XCTAssertEqual(String(bytes: buffer, encoding: .utf8), "1234567890")
    XCTAssertFalse(iStreamCore.iStreamable.isEndOfStream())

    try iStreamCore.iStreamable.seek(offset: 10, streamSeekType: StreamSeekType.begin)
    XCTAssertFalse(iStreamCore.iStreamable.isEndOfStream())

    let largeBuffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: 100)
    defer {
      largeBuffer.deallocate()
    }

    length = try iStreamCore.iStreamable.read(buffer: largeBuffer)
    XCTAssertEqual(length, capacity)
    XCTAssertEqual(String(bytes: largeBuffer[..<length!], encoding: .utf8), "0987654321")
    XCTAssertTrue(iStreamCore.iStreamable.isEndOfStream())

    length = try iStreamCore.iStreamable.read(buffer: largeBuffer)
    XCTAssertEqual(length, nil)

    length = try iStreamCore.iStreamable.read(buffer: largeBuffer)
    XCTAssertEqual(length, nil)

    XCTAssertTrue(iStreamCore.iStreamable.isEndOfStream())
  }

}
