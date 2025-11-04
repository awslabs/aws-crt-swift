import AwsCCal

import struct Foundation.Data
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import struct Foundation.Date
import struct Foundation.TimeInterval

public class ECKeyPair {

  public enum ECAlgorithm: UInt32 {
    case p256 = 0
    case p384 = 1
  }

  public enum ECExportFormat: UInt32 {
    case sec1 = 0
    case pkcs8 = 1
    case spki = 2
  }

  public typealias ECRawSignature = (r: Data, s: Data)
  public typealias ECPublicCoords = (x: Data, y: Data)

  public static let maxExportSize = 512

  let rawValue: UnsafeMutablePointer<aws_ecc_key_pair>

  private init(rawValue: UnsafeMutablePointer<aws_ecc_key_pair>) {
    self.rawValue = rawValue
  }

  static func generate(algorithm: ECAlgorithm) throws -> ECKeyPair {
    guard
      let rawValue = aws_ecc_key_pair_new_generate_random(
        allocator.rawValue, aws_ecc_curve_name(algorithm.rawValue))
    else {
      throw CommonRunTimeError.crtError(.makeFromLastError())
    }
    return ECKeyPair(rawValue: rawValue)
  }

  static func fromDer(data: Data) throws -> ECKeyPair {
    try data.withUnsafeBytes { bufferPointer in
      var byteCursor = aws_byte_cursor_from_array(bufferPointer.baseAddress, data.count)
      guard
        let rawValue = aws_ecc_key_pair_new_from_asn1(allocator.rawValue, &byteCursor)
      else {
        throw CommonRunTimeError.crtError(.makeFromLastError())
      }
      return ECKeyPair(rawValue: rawValue)
    }
  }

  /// Decodes der ec signature into raw r and s components
  static public func decodeDerEcSignature(signature: Data) throws -> ECKeyPair.ECRawSignature {
    var rCur = aws_byte_cursor()
    var sCur = aws_byte_cursor()

    return try signature.withUnsafeBytes { signaturePointer -> ECKeyPair.ECRawSignature in
      let signatureCursor = aws_byte_cursor_from_array(
        signaturePointer.baseAddress,
        signature.count
      )

      guard
        aws_ecc_decode_signature_der_to_raw(
          allocator.rawValue,
          signatureCursor,
          &rCur,
          &sCur
        ) == AWS_OP_SUCCESS
      else {
        throw CommonRunTimeError.crtError(.makeFromLastError())
      }

      let rData = Data(bytes: rCur.ptr, count: rCur.len)
      let sData = Data(bytes: sCur.ptr, count: sCur.len)
      return ECKeyPair.ECRawSignature(r: rData, s: sData)
    }
  }

  /// Encode raw ec signature into der format
  static public func encodeRawECSignature(signature: ECKeyPair.ECRawSignature) throws -> Data {
    return try signature.r.withUnsafeBytes { rPointer in
      let rCursor = aws_byte_cursor_from_array(rPointer.baseAddress, signature.r.count)
      return try signature.s.withUnsafeBytes { sPointer in
        let sCursor = aws_byte_cursor_from_array(sPointer.baseAddress, signature.s.count)

        let bufferSize = signature.r.count + signature.s.count + 32
        var bufferData = Data(count: bufferSize)
        var newBufferSize = 0
        try bufferData.withUnsafeMutableBytes { bufferPointer in
          var buffer = aws_byte_buf_from_empty_array(bufferPointer.baseAddress, bufferSize)
          guard
            aws_ecc_encode_signature_raw_to_der(
              allocator.rawValue,
              rCursor, sCursor, &buffer) == AWS_OP_SUCCESS
          else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
          }
          newBufferSize = buffer.len
        }
        bufferData.count = newBufferSize
        return bufferData
      }
    }
  }

  public func exportKey(format: ECKeyPair.ECExportFormat) throws -> Data {
    var bufferData = Data(count: ECKeyPair.maxExportSize)
    try bufferData.withUnsafeMutableBytes { bufferPointer in
      var buffer = aws_byte_buf_from_empty_array(bufferPointer.baseAddress, ECKeyPair.maxExportSize)
      guard
        aws_ecc_key_pair_export(rawValue, aws_ecc_key_export_format(format.rawValue), &buffer)
          == AWS_OP_SUCCESS
      else {
        throw CommonRunTimeError.crtError(.makeFromLastError())
      }
    }
    return bufferData
  }

  public func getPublicCoords() throws -> ECKeyPair.ECPublicCoords {
    var xCoord = aws_byte_cursor()
    var yCoord = aws_byte_cursor()
    aws_ecc_key_pair_get_public_key(rawValue, &xCoord, &yCoord)
    let xData = Data(bytes: xCoord.ptr, count: xCoord.len)
    let yData = Data(bytes: yCoord.ptr, count: yCoord.len)

    return ECKeyPair.ECPublicCoords(x: xData, y: yData)
  }

  public func sign(digest: Data) throws -> Data {
    let bufferSize = aws_ecc_key_pair_signature_length(rawValue)
    var bufferData = Data(count: bufferSize)
    var newBufferSize = 0
    try digest.withUnsafeBytes { bufferPointer in
      var byteCursor = aws_byte_cursor_from_array(bufferPointer.baseAddress, digest.count)
      try bufferData.withUnsafeMutableBytes { bufferPointer in
        var buffer = aws_byte_buf_from_empty_array(bufferPointer.baseAddress, bufferSize)
        guard aws_ecc_key_pair_sign_message(rawValue, &byteCursor, &buffer) == AWS_OP_SUCCESS else {
          throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        newBufferSize = buffer.len
      }
    }
    bufferData.count = newBufferSize
    return bufferData
  }

  public func verify(digest: Data, signature: Data) -> Bool {
    return digest.withUnsafeBytes { digestPointer -> Bool in
      var digestCursor = aws_byte_cursor_from_array(digestPointer.baseAddress, digest.count)

      return signature.withUnsafeBytes { signaturePointer -> Bool in
        var signatureCursor = aws_byte_cursor_from_array(
          signaturePointer.baseAddress, signature.count)
        return aws_ecc_key_pair_verify_signature(rawValue, &digestCursor, &signatureCursor)
          == AWS_OP_SUCCESS
      }
    }
  }

  deinit {
    aws_ecc_key_pair_release(rawValue)
  }
}
