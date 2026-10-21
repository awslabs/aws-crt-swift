//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCCommon
import Foundation
import XCTest

@testable import AwsCommonRuntimeKit

class EndpointsBDDEngineTests: XCBaseTestCase {

  /// Resolves `context` with a BDD engine whose bytecode stays alive for the engine's lifetime
  func resolve(
    _ context: EndpointsRequestContext, bytecodeResource: String = "endpoint-bdd-encoded"
  ) throws -> ResolvedEndpoint {
    let bytecodeURL = Bundle.module.url(forResource: bytecodeResource, withExtension: "bin")!
    let partitionsPath = Bundle.module.path(
      forResource: "endpoint-engine-partitions", ofType: "json")!
    let partitions = try String(contentsOfFile: partitionsPath, encoding: .utf8)
    let bytecode = try Data(contentsOf: bytecodeURL)
    // The engine reads the bytecode in place, so keep it alive while the engine is in use
    return try withExtendedLifetime(bytecode) {
      let engine = try EndpointsBDDEngine(partitions: partitions, bytecode: bytecode)
      return try engine.resolve(context: context)
    }
  }

  func testResolveVirtualHost() throws {
    let context = try EndpointsRequestContext()
    try context.add(name: "Region", value: "us-west-2")
    try context.add(name: "Bucket", value: "bucket-name")
    guard case .endpoint(let url, _, _) = try resolve(context) else {
      XCTFail("Endpoint resolved to an error")
      return
    }
    XCTAssertEqual("https://bucket-name.s3.us-west-2.amazonaws.com", url)
  }

  func testResolvePathStyle() throws {
    let context = try EndpointsRequestContext()
    try context.add(name: "Region", value: "us-west-2")
    try context.add(name: "ForcePathStyle", value: true)
    try context.add(name: "Bucket", value: "bucket-name")
    guard case .endpoint(let url, _, _) = try resolve(context) else {
      XCTFail("Endpoint resolved to an error")
      return
    }
    XCTAssertEqual("https://s3.us-west-2.amazonaws.com/bucket-name", url)
  }

  func testResolveProperties() throws {
    let context = try EndpointsRequestContext()
    try context.add(name: "Region", value: "us-west-2")
    try context.add(name: "Bucket", value: "bucket-name")
    guard
      case .endpoint(_, let headers, let properties) = try resolve(context)
    else {
      XCTFail("Endpoint resolved to an error")
      return
    }
    let expectedProperties: [String: EndpointProperty] = [
      "authSchemes": .array([
        .dictionary([
          "disableDoubleEncoding": .bool(true),
          "name": .string("sigv4"),
          "signingName": .string("s3"),
          "signingRegion": .string("us-west-2"),
        ])
      ])
    ]
    XCTAssertEqual(expectedProperties, properties)
    XCTAssertEqual([:], headers)
  }

  func testResolveHeaders() throws {
    let context = try EndpointsRequestContext()
    try context.add(name: "Region", value: "us-west-2")
    guard
      case .endpoint(let url, let headers, let properties) = try resolve(
        context, bytecodeResource: "endpoint-engine-headers")
    else {
      XCTFail("Endpoint resolved to an error")
      return
    }
    XCTAssertEqual("https://service.us-west-2.amazonaws.com", url)
    let expectedHeaders = [
      "x-amz-region": ["us-west-2"],
      "x-amz-multi": ["*", "us-west-2"],
    ]
    XCTAssertEqual(expectedHeaders, headers)
    let expectedProperties: [String: EndpointProperty] = [
      "authSchemes": .array([
        .dictionary([
          "name": .string("sigv4"),
          "signingName": .string("service"),
          "signingRegion": .string("us-west-2"),
        ])
      ])
    ]
    XCTAssertEqual(expectedProperties, properties)
  }

  func testResolveError() throws {
    let context = try EndpointsRequestContext()
    try context.add(name: "Region", value: "us-east-1")
    try context.add(name: "Bucket", value: "bucket-name")
    try context.add(name: "Accelerate", value: true)
    try context.add(name: "UseFIPS", value: true)
    guard case .error(let message) = try resolve(context) else {
      XCTFail("Endpoint resolved to an endpoint")
      return
    }
    XCTAssertEqual("Accelerate cannot be used with FIPS", message)
  }

  func testInvalidBytecodeThrows() throws {
    let partitionsPath = Bundle.module.path(
      forResource: "endpoint-engine-partitions", ofType: "json")!
    let partitions = try String(contentsOfFile: partitionsPath, encoding: .utf8)

    let invalidBytecodes: [(name: String, bytes: [UInt8])] = [
      ("too short for magic number", [0x00, 0x01, 0x02]),
      ("wrong magic number", [0x00, 0x01, 0x02, 0x03]),
      ("magic number only", [0x52, 0x44, 0x50, 0x45]),  // "RDPE", then truncated
    ]
    for invalid in invalidBytecodes {
      XCTAssertThrowsError(
        try EndpointsBDDEngine(partitions: partitions, bytecode: Data(invalid.bytes)),
        invalid.name
      ) { error in
        guard case CommonRunTimeError.crtError(let crtError) = error else {
          return XCTFail("\(invalid.name): unexpected error \(error)")
        }
        XCTAssertEqual(Int32(AWS_ERROR_INVALID_ARGUMENT.rawValue), crtError.code, invalid.name)
      }
    }
  }
}
