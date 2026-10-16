//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import Foundation
import XCTest

@testable import AwsCommonRuntimeKit

/// Each test resolves the same case with both the rule engine and the BDD engine.
/// The fixtures are the same simple ruleset in tree form (JSON) and compiled BDD form (bytecode).
class EndpointsEngineTests: XCBaseTestCase {

  func testRegionalEndpoint() throws {
    try runBothEngines(
      buildContext: { try $0.add(name: "Region", value: "us-west-2") },
      expectedURL: "https://example.us-west-2.amazonaws.com")
  }

  func testGlobalEndpoint() throws {
    try runBothEngines(
      buildContext: { _ in },  // no Region
      expectedURL: "https://example.amazonaws.com")
  }

  private func runBothEngines(
    buildContext: (EndpointsRequestContext) throws -> Void,
    expectedURL: String
  ) throws {
    let partitions = try fixtureString("endpoint-engine-partitions", "json")
    let ruleEngine = try EndpointsRuleEngine(
      partitions: partitions, ruleSet: try fixtureString("endpoint-engine-model", "json"))
    let bddEngine = try EndpointsBDDEngine(
      partitions: partitions, bytecode: try fixtureData("endpoint-engine-model", "bin"))

    let engines: [(name: String, resolve: (EndpointsRequestContext) throws -> ResolvedEndpoint)] = [
      ("rule", ruleEngine.resolve),
      ("bdd", bddEngine.resolve),
    ]
    for engine in engines {
      let context = try EndpointsRequestContext()
      try buildContext(context)
      guard case .endpoint(let url, _, _) = try engine.resolve(context) else {
        XCTFail("\(engine.name) engine resolved to an error")
        continue
      }
      XCTAssertEqual(expectedURL, url, "\(engine.name) engine")
    }
  }

  private func fixtureString(_ name: String, _ ext: String) throws -> String {
    try String(
      contentsOf: Bundle.module.url(forResource: name, withExtension: ext)!, encoding: .utf8)
  }

  private func fixtureData(_ name: String, _ ext: String) throws -> Data {
    try Data(contentsOf: Bundle.module.url(forResource: name, withExtension: ext)!)
  }
}
