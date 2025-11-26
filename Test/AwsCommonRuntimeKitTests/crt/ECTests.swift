//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
import AwsCCommon

@testable import AwsCommonRuntimeKit

class ECTests: XCBaseTestCase {

  func testP256() throws {
    let input = "Hello"
    let sha256 = try input.data(using: .utf8)!.computeSHA256()

    let ecKey = try ECKeyPair.generate(algorithm: ECKeyPair.ECAlgorithm.p256)
    let signature = try ecKey.sign(digest: sha256)

    let raw = try ECKeyPair.decodeDerEcSignature(signature: signature)
    XCTAssertEqual(
      signature,
      try ECKeyPair.encodeRawECSignature(signature: ECKeyPair.ECRawSignature(r: raw.r, s: raw.s)))

    XCTAssertTrue(ecKey.verify(digest: sha256, signature: signature))
  }

  func testP384() throws {
    let input = "Hello"
    let sha256 = try input.data(using: .utf8)!.computeSHA256()

    let ecKey = try ECKeyPair.generate(algorithm: ECKeyPair.ECAlgorithm.p384)
    let signature = try ecKey.sign(digest: sha256)

    let raw = try ECKeyPair.decodeDerEcSignature(signature: signature)
    XCTAssertEqual(
      signature,
      try ECKeyPair.encodeRawECSignature(signature: ECKeyPair.ECRawSignature(r: raw.r, s: raw.s)))

    XCTAssertTrue(ecKey.verify(digest: sha256, signature: signature))
  }

  func testImport() throws {
    let input = "Hello"
    let sha256 = try input.data(using: .utf8)!.computeSHA256()

    let sec1Key = """
      MHcCAQEEIHjt7c+VnkIkN6RW7QgZPFNLb/9AZEhqSYYMtwrlLb3WoAoGCCqGSM49AwEHoUQDQgAEv2F\
      jRpMtADMZ4zoZxshV9chEkembgzZnXSUNe+DA8dKqXN/7qTcZjYJHKIi+Rn88zUGqCJo3DWF/X+ufVf\
      dU2g==
      """

    guard let keyData = Data(base64Encoded: sec1Key) else {
      XCTFail("Failed to decode base64 string")
      return
    }

    let ecKey = try ECKeyPair.fromDer(data: keyData)
    let signature = try ecKey.sign(digest: sha256)

    let raw = try ECKeyPair.decodeDerEcSignature(signature: signature)
    XCTAssertEqual(
      signature,
      try ECKeyPair.encodeRawECSignature(signature: ECKeyPair.ECRawSignature(r: raw.r, s: raw.s)))

    XCTAssertTrue(ecKey.verify(digest: sha256, signature: signature))
  }

  func testDecodePadded() throws {

    let signature: [UInt8] = [
      0x30, 0x42, 0x02, 0x1f, 0x2d, 0x2a, 0xad, 0xce, 0xbc, 0x1b, 0x3f, 0x78,
      0xec, 0xd1, 0x12, 0x53, 0x9e, 0xc0, 0xe3, 0x44, 0x7b, 0x37, 0x5f, 0x6a,
      0x99, 0xca, 0x0b, 0x27, 0xb5, 0x4c, 0x31, 0xda, 0x0e, 0x6c, 0x5e, 0x02,
      0x1f, 0x47, 0xfb, 0x3d, 0xbd, 0xff, 0xb8, 0x58, 0xf4, 0xba, 0x8a, 0x03,
      0xe7, 0xb4, 0x83, 0xe6, 0xb8, 0xc9, 0x46, 0xa8, 0x0a, 0xd8, 0x46, 0xfa,
      0x80, 0x0a, 0xd8, 0xca, 0xc5, 0x3f, 0x8e, 0xbd
    ]
    let signatureData = Data(_: signature)

    let expected: [UInt8] = [
      0x00, 0x2d, 0x2a, 0xad, 0xce, 0xbc, 0x1b, 0x3f, 0x78, 0xec, 0xd1, 0x12, 0x53,
      0x9e, 0xc0, 0xe3, 0x44, 0x7b, 0x37, 0x5f, 0x6a, 0x99, 0xca, 0x0b, 0x27, 0xb5,
      0x4c, 0x31, 0xda, 0x0e, 0x6c, 0x5e, 0x00, 0x47, 0xfb, 0x3d, 0xbd, 0xff, 0xb8,
      0x58, 0xf4, 0xba, 0x8a, 0x03, 0xe7, 0xb4, 0x83, 0xe6, 0xb8, 0xc9, 0x46, 0xa8,
      0x0a, 0xd8, 0x46, 0xfa, 0x80, 0x0a, 0xd8, 0xca, 0xc5, 0x3f, 0x8e, 0xbd
    ]
    let expectedData = Data(_: expected)

    let raw = try ECKeyPair.decodeDerEcSignatureToPaddedPair(signature: signatureData, padTo: 32)

    XCTAssertEqual(expectedData, raw)
  }

}
