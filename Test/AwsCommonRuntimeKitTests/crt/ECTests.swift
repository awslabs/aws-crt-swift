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

}
