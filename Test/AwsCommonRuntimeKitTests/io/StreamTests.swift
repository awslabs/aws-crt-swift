//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
import Foundation
@testable import AwsCommonRuntimeKit

class StreamTests: CrtXCBaseTestCase {

  func testFileStream() throws {
    let fileHandle = FileHandle(forReadingAtPath: Bundle.module.path(forResource: "stream-test", ofType: "txt")!)!
    let iStreamCore = IStreamCore(iStreamable: fileHandle, allocator: allocator)
    try testStream(iStreamCore: iStreamCore)
  }

  func testByteBufferStream() throws {
    let byteBuffer = ByteBuffer(data: "12345678900987654321".data(using: .utf8)!)
    let iStreamCore = IStreamCore(iStreamable: byteBuffer, allocator: allocator)
    try testStream(iStreamCore: iStreamCore)
  }

  func testStream(iStreamCore: IStreamCore) throws {

    let capacity = 10
    let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: capacity)
    defer {
      buffer.deallocate()
    }

    XCTAssertEqual(20, try iStreamCore.iStreamable.length())

    var length = try iStreamCore.iStreamable.read(buffer: buffer)
    XCTAssertEqual(length, capacity)
    XCTAssertEqual(String(bytes: buffer, encoding: .utf8), "1234567890")

    length = try iStreamCore.iStreamable.read(buffer: buffer)
    XCTAssertEqual(length, capacity)
    XCTAssertEqual(String(bytes: buffer, encoding: .utf8), "0987654321")

    length = try iStreamCore.iStreamable.read(buffer: buffer)
    XCTAssertEqual(length, nil)


    try iStreamCore.iStreamable.seek(offset: 0, streamSeekType: StreamSeekType.begin)
    length = try iStreamCore.iStreamable.read(buffer: buffer)
    XCTAssertEqual(length, capacity)
    XCTAssertEqual(String(bytes: buffer, encoding: .utf8), "1234567890")

    try iStreamCore.iStreamable.seek(offset: 10, streamSeekType: StreamSeekType.begin)
    length = try iStreamCore.iStreamable.read(buffer: buffer)
    XCTAssertEqual(length, capacity)
    XCTAssertEqual(String(bytes: buffer, encoding: .utf8), "0987654321")

    length = try iStreamCore.iStreamable.read(buffer: buffer)
    XCTAssertEqual(length, nil)
  }
}
