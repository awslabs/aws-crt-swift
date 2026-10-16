//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCSdkUtils
import Foundation

/// Shared behavior for CRT endpoint engines (rule set and BDD)
protocol EndpointsEngine {
  /// Run this engine's CRT resolve call. The caller is responsible for releasing the result.
  /// - Parameter context: The request context to use for endpoint resolution
  /// - Returns: The CRT resolved endpoint
  func resolveCRTEndpoint(context: EndpointsRequestContext) throws
    -> UnsafeMutablePointer<aws_endpoints_resolved_endpoint>

  /// Get the URL of the resolved endpoint
  /// - Returns: The URL of the resolved endpoint
  func url(from rawValue: UnsafeMutablePointer<aws_endpoints_resolved_endpoint>) throws -> String

  /// Get headers of the resolved endpoint
  /// - Returns: The headers of the resolved endpoint
  func headers(from rawValue: UnsafeMutablePointer<aws_endpoints_resolved_endpoint>) throws
    -> [String: [String]]

  /// Get the properties of the resolved endpoint
  /// - Returns: The properties of the resolved endpoint
  func properties(from rawValue: UnsafeMutablePointer<aws_endpoints_resolved_endpoint>) throws
    -> [String: EndpointProperty]

  /// Get the error message of the resolved endpoint
  /// - Returns: The error message of the resolved endpoint
  func errorMessage(from rawValue: UnsafeMutablePointer<aws_endpoints_resolved_endpoint>) throws
    -> String
}

extension EndpointsEngine {

  /// Resolve an endpoint and convert the CRT result into a ResolvedEndpoint
  /// - Parameter context: The request context to use for endpoint resolution
  /// - Returns: The resolved endpoint
  func resolveEndpoint(context: EndpointsRequestContext) throws -> ResolvedEndpoint {
    let resolvedEndpoint = try resolveCRTEndpoint(context: context)
    defer {
      aws_endpoints_resolved_endpoint_release(resolvedEndpoint)
    }

    let type = aws_endpoints_resolved_endpoint_get_type(resolvedEndpoint)

    if type == AWS_ENDPOINTS_RESOLVED_ENDPOINT {
      return ResolvedEndpoint.endpoint(
        url: try url(from: resolvedEndpoint),
        headers: try headers(from: resolvedEndpoint),
        properties: try properties(from: resolvedEndpoint))
    } else {
      return ResolvedEndpoint.error(message: try errorMessage(from: resolvedEndpoint))
    }
  }

  func url(from rawValue: UnsafeMutablePointer<aws_endpoints_resolved_endpoint>) throws -> String {
    var url = aws_byte_cursor()
    guard aws_endpoints_resolved_endpoint_get_url(rawValue, &url) == AWS_OP_SUCCESS else {
      throw CommonRunTimeError.crtError(.makeFromLastError())
    }
    guard url.len > 0 else {
      fatalError("Url length can not be zero")
    }

    return url.toString()
  }

  func headers(from rawValue: UnsafeMutablePointer<aws_endpoints_resolved_endpoint>) throws
    -> [String: [String]]
  {
    var cHeaders: UnsafePointer<aws_hash_table>! = nil
    guard aws_endpoints_resolved_endpoint_get_headers(rawValue, &cHeaders) == AWS_OP_SUCCESS else {
      throw CommonRunTimeError.crtError(.makeFromLastError())
    }

    var headers: [String: [String]] = [:]

    var iter = aws_hash_iter_begin(cHeaders)
    while !aws_hash_iter_done(&iter) {
      // Get the key
      let keyPtr = iter.element.key.bindMemory(to: aws_string.self, capacity: 1)
      let key = String(awsString: keyPtr)!

      // Get the value
      let arrayPtr = iter.element.value.bindMemory(to: aws_array_list.self, capacity: 1)
      headers[key] = arrayPtr.pointee.awsStringListToStringArray()
      aws_hash_iter_next(&iter)
    }

    return headers
  }

  func properties(from rawValue: UnsafeMutablePointer<aws_endpoints_resolved_endpoint>) throws
    -> [String: EndpointProperty]
  {
    var properties = aws_byte_cursor()
    guard aws_endpoints_resolved_endpoint_get_properties(rawValue, &properties) == AWS_OP_SUCCESS
    else {
      throw CommonRunTimeError.crtError(.makeFromLastError())
    }
    guard properties.len > 0 else {
      return [String: EndpointProperty]()
    }
    let data = Data(bytes: properties.ptr, count: properties.len)
    return try JSONDecoder().decode([String: EndpointProperty].self, from: data)
  }

  func errorMessage(from rawValue: UnsafeMutablePointer<aws_endpoints_resolved_endpoint>) throws
    -> String
  {
    var error = aws_byte_cursor()
    guard aws_endpoints_resolved_endpoint_get_error(rawValue, &error) == AWS_OP_SUCCESS else {
      throw CommonRunTimeError.crtError(.makeFromLastError())
    }
    return error.toString()
  }
}
