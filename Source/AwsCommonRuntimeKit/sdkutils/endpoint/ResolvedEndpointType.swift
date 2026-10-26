//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCSdkUtils
import Foundation

/// Resolved endpoint type
public enum ResolvedEndpoint {
  /// Used for endpoints that are resolved successfully
  case endpoint(url: String, headers: [String: [String]], properties: [String: EndpointProperty])

  /// Used for endpoints that resolve to an error
  case error(message: String)
}

extension ResolvedEndpoint {

  /// Convert a CRT resolved endpoint into a ResolvedEndpoint. Does not release `crtEndpoint`.
  /// - Parameter crtEndpoint: The CRT resolved endpoint
  init(crtEndpoint: UnsafeMutablePointer<aws_endpoints_resolved_endpoint>) throws {
    let reader = CRTResolvedEndpointReader(rawValue: crtEndpoint)
    if reader.isEndpoint {
      self = .endpoint(
        url: try reader.url(), headers: try reader.headers(), properties: try reader.properties())
    } else {
      self = .error(message: try reader.errorMessage())
    }
  }
}

/// Reads the fields of a CRT resolved endpoint
struct CRTResolvedEndpointReader {
  let rawValue: UnsafeMutablePointer<aws_endpoints_resolved_endpoint>

  /// True if the resolved endpoint is an endpoint, false if it is an error
  var isEndpoint: Bool {
    aws_endpoints_resolved_endpoint_get_type(rawValue) == AWS_ENDPOINTS_RESOLVED_ENDPOINT
  }

  /// Get the URL of the resolved endpoint
  /// - Returns: The URL of the resolved endpoint
  func url() throws -> String {
    var url = aws_byte_cursor()
    guard aws_endpoints_resolved_endpoint_get_url(rawValue, &url) == AWS_OP_SUCCESS else {
      throw CommonRunTimeError.crtError(.makeFromLastError())
    }
    guard url.len > 0 else {
      fatalError("Url length can not be zero")
    }

    return url.toString()
  }

  /// Get headers of the resolved endpoint
  /// - Returns: The headers of the resolved endpoint
  func headers() throws -> [String: [String]] {
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

  /// Get the properties of the resolved endpoint
  /// - Returns: The properties of the resolved endpoint
  func properties() throws -> [String: EndpointProperty] {
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

  /// Get the error message of the resolved endpoint
  /// - Returns: The error message of the resolved endpoint
  func errorMessage() throws -> String {
    var error = aws_byte_cursor()
    guard aws_endpoints_resolved_endpoint_get_error(rawValue, &error) == AWS_OP_SUCCESS else {
      throw CommonRunTimeError.crtError(.makeFromLastError())
    }
    return error.toString()
  }
}
