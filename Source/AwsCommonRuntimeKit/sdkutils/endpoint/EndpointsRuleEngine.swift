//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCSdkUtils
import Foundation

/// Rule engine for matching endpoint rules
public class EndpointsRuleEngine: EndpointsEngine {

  let rawValue: OpaquePointer

  /// Initialize a new rule engine
  /// - Parameters:
  ///   - partitions: JSON string containing partition data
  ///   - ruleSet: The rule set string to use for the rule engine
  public init(partitions: String, ruleSet: String) throws {
    let getRawValue: () throws -> OpaquePointer = {
      guard
        let partitions =
          (partitions.withByteCursor { partitionsCursor in
            aws_partitions_config_new_from_string(allocator.rawValue, partitionsCursor)
          })
      else {
        throw CommonRunTimeError.crtError(.makeFromLastError())
      }
      defer {
        aws_partitions_config_release(partitions)
      }

      guard
        let ruleSet =
          (ruleSet.withByteCursor { ruleSetCursor in
            aws_endpoints_ruleset_new_from_string(allocator.rawValue, ruleSetCursor)
          })
      else {
        throw CommonRunTimeError.crtError(.makeFromLastError())
      }
      defer {
        aws_endpoints_ruleset_release(ruleSet)
      }

      guard let rawValue = aws_endpoints_rule_engine_new(allocator.rawValue, ruleSet, partitions)
      else {
        throw CommonRunTimeError.crtError(.makeFromLastError())
      }
      return rawValue
    }

    self.rawValue = try getRawValue()
  }

  /// Resolve an endpoint from the rule engine using the provided request context
  /// - Parameter context: The request context to use for endpoint resolution
  /// - Returns: The resolved endpoint
  public func resolve(context: EndpointsRequestContext) throws -> ResolvedEndpoint {
    try resolveEndpoint(context: context)
  }

  func resolveCRTEndpoint(context: EndpointsRequestContext) throws
    -> UnsafeMutablePointer<aws_endpoints_resolved_endpoint>
  {
    var resolvedEndpoint: UnsafeMutablePointer<aws_endpoints_resolved_endpoint>! = nil
    guard
      aws_endpoints_rule_engine_resolve(rawValue, context.rawValue, &resolvedEndpoint)
        == AWS_OP_SUCCESS
    else {
      throw CommonRunTimeError.crtError(.makeFromLastError())
    }
    return resolvedEndpoint
  }

  /// Get headers of the resolved endpoint
  /// - Returns: The headers of the resolved endpoint
  public func getHeaders(rawValue: UnsafeMutablePointer<aws_endpoints_resolved_endpoint>) throws
    -> [String: [String]]
  {
    try headers(from: rawValue)
  }

  deinit {
    aws_endpoints_rule_engine_release(rawValue)
  }
}
