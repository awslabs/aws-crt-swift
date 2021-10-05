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
        XCTAssertEqual(sha256, "mOvg7kNh8w/hQ7vi3KpSGkjWvlpbIqrajGWk8IMwvwo=")
    }
    
    func testSha256_EmptyString() throws {
        let empty = "".data(using: .utf8)!
        let sha256 = ByteBuffer(data: empty).base64EncodedSha256()
        XCTAssertEqual(sha256, "47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=")
    }
    
    func testSha256_payload() throws {
        let payload = "{\"foo\":\"base64 encoded sha256 checksum\"}".data(using: .utf8)!
        let sha256 = ByteBuffer(data: payload).base64EncodedSha256()
        
        XCTAssertEqual("lBSnDP4sj/yN8eIVOJlv+vC56hw+7JtN0132GiMQXRg=", sha256)
    }
    
    func testSha256LongString() throws {
        let longString = "Hi John You are the best for helping me. And also really smart. And Yili is a lucky girl.".data(using: .utf8)!
        let sha256byteBuffer: ByteBuffer = ByteBuffer(data: longString)
        let data: Data = sha256byteBuffer.sha256()
        //print(data)
        let base64encodedString = data.base64EncodedString()
        XCTAssertEqual("dJFvX5qSEEaZlEQKsL35lxbsPP14VsKav0RCOQEOfyE=", base64encodedString)
//        print(data.base64EncodedData())
        //let string = String(data: data, encoding: .utf8)
//        print(string)
        //.base64EncodedSha256()
//        sha256byteBuffer.sha256()
        //XCTAssertEqual(sha256, "Yo+bIb5g8Pa/2kXn2uoJTnp0+0ILn2/QigSNISP11L0=")
    }
}

