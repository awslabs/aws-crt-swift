//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCSdkUtils
import Foundation

/// BDD engine for resolving endpoints from compiled BDD bytecode
public class EndpointsBDDEngine {

  let rawValue: OpaquePointer

  /// Initialize a new BDD engine
  ///
  /// - Parameters:
  ///   - partitions: JSON string containing partition data
  ///   - bytecode: Compiled BDD bytecode
  public init(partitions: String, bytecode: Data) throws {
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
        let rawValue =
          (bytecode.withByteCursor { bytecodeCursor in
            aws_endpoints_bdd_engine_new_from_bytecode(
              allocator.rawValue, bytecodeCursor, partitions)
          })
      else {
        throw CommonRunTimeError.crtError(.makeFromLastError())
      }
      return OpaquePointer(rawValue)
    }

    self.rawValue = try getRawValue()
  }

  /// Resolve an endpoint from the BDD engine using the provided request context
  /// - Parameter context: The request context to use for endpoint resolution
  /// - Returns: The resolved endpoint
  public func resolve(context: EndpointsRequestContext) throws -> ResolvedEndpoint {
    var resolvedEndpoint: UnsafeMutablePointer<aws_endpoints_resolved_endpoint>! = nil
    guard
      aws_endpoints_bdd_engine_resolve(
        UnsafeMutablePointer(rawValue), context.rawValue, &resolvedEndpoint)
        == AWS_OP_SUCCESS
    else {
      throw CommonRunTimeError.crtError(.makeFromLastError())
    }
    defer {
      aws_endpoints_resolved_endpoint_release(resolvedEndpoint)
    }
    return try ResolvedEndpoint(crtEndpoint: resolvedEndpoint)
  }

  deinit {
    aws_endpoints_bdd_engine_release(UnsafeMutablePointer(rawValue))
  }
}
