//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import Foundation
import XCTest

@testable import AwsCommonRuntimeKit

class EndpointsBDDEngineTests: XCBaseTestCase {

  func makeEngine() throws -> EndpointsBDDEngine {
    let bytecodeURL = Bundle.module.url(forResource: "endpoint-bdd-encoded", withExtension: "bin")!
    let partitionsPath = Bundle.module.path(
      forResource: "endpoint-engine-partitions", ofType: "json")!
    return try EndpointsBDDEngine(
      partitions: try String(contentsOfFile: partitionsPath, encoding: .utf8),
      bytecode: try Data(contentsOf: bytecodeURL))
  }

  func testResolveVirtualHost() throws {
    let context = try EndpointsRequestContext()
    try context.add(name: "Region", value: "us-west-2")
    try context.add(name: "Bucket", value: "bucket-name")
    guard case .endpoint(let url, _, _) = try makeEngine().resolve(context: context) else {
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
    guard case .endpoint(let url, _, _) = try makeEngine().resolve(context: context) else {
      XCTFail("Endpoint resolved to an error")
      return
    }
    XCTAssertEqual("https://s3.us-west-2.amazonaws.com/bucket-name", url)
  }

  func testInvalidBytecodeThrows() throws {
    let partitionsPath = Bundle.module.path(
      forResource: "endpoint-engine-partitions", ofType: "json")!
    XCTAssertThrowsError(
      try EndpointsBDDEngine(
        partitions: try String(contentsOfFile: partitionsPath, encoding: .utf8),
        bytecode: Data([0x00, 0x01, 0x02])))
  }
}
