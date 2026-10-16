//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCSdkUtils
import Foundation

/// BDD engine for resolving endpoints from compiled BDD bytecode
public class EndpointsBDDEngine: EndpointsEngine {

  let rawValue: UnsafeMutablePointer<aws_endpoints_bdd_engine>
  private var bytecodeBuffer: aws_byte_buf

  /// Initialize a new BDD engine
  /// - Parameters:
  ///   - partitions: JSON string containing partition data
  ///   - bytecode: Compiled BDD bytecode
  public init(partitions: String, bytecode: Data) throws {
    var bytecodeBuffer = aws_byte_buf()
    guard
      bytecode.withAWSByteCursorPointer({ bytecodeCursor in
        aws_byte_buf_init_copy_from_cursor(
          &bytecodeBuffer, allocator.rawValue, bytecodeCursor.pointee)
      }) == AWS_OP_SUCCESS
    else {
      throw CommonRunTimeError.crtError(.makeFromLastError())
    }

    let getRawValue: () throws -> UnsafeMutablePointer<aws_endpoints_bdd_engine> = {
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
        let rawValue = aws_endpoints_bdd_engine_new_from_bytecode(
          allocator.rawValue, aws_byte_cursor_from_buf(&bytecodeBuffer), partitions)
      else {
        throw CommonRunTimeError.crtError(.makeFromLastError())
      }
      return rawValue
    }

    do {
      self.rawValue = try getRawValue()
    } catch {
      aws_byte_buf_clean_up(&bytecodeBuffer)
      throw error
    }
    self.bytecodeBuffer = bytecodeBuffer
  }

  /// Resolve an endpoint from the BDD engine using the provided request context
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
      aws_endpoints_bdd_engine_resolve(rawValue, context.rawValue, &resolvedEndpoint)
        == AWS_OP_SUCCESS
    else {
      throw CommonRunTimeError.crtError(.makeFromLastError())
    }
    return resolvedEndpoint
  }

  deinit {
    aws_endpoints_bdd_engine_release(rawValue)
    aws_byte_buf_clean_up(&bytecodeBuffer)
  }
}
