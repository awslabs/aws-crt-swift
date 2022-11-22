//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCSdkUtils
import Foundation

/// Resolved endpoint
public class CRTAWSEndpointResolvedEndpoint {
    let rawValue: OpaquePointer

    /// Initialize a new resolved endpoint
    /// - Parameter rawValue: The raw value of the resolved endpoint
    init(rawValue: OpaquePointer) {
        self.rawValue = rawValue
    }

    /// Get the type of the resolved endpoint
    /// - Returns: The type of the resolved endpoint
    public func getType() -> CRTAWSEndpointsResolvedEndpointType {
        let type = aws_endpoints_resolved_endpoint_get_type(rawValue)
        return CRTAWSEndpointsResolvedEndpointType(rawValue: type)
    }

    /// Get the URL of the resolved endpoint
    /// - Returns: The URL of the resolved endpoint
    public func getURL() throws -> String? {
        var url = aws_byte_cursor()
        guard aws_endpoints_resolved_endpoint_get_url(rawValue, &url) == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        return url.toString()
    }

    /// Get the properties of the resolved endpoint
    /// - Returns: The properties of the resolved endpoint
    public func getProperties() throws -> [String: AnyHashable]? {
        var properties = aws_byte_cursor()
        guard aws_endpoints_resolved_endpoint_get_properties(rawValue, &properties) == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }

        guard let data = properties.toString()?.data(using: .utf8) else {
            return nil
        }
        return try JSONDecoder().decode([String: EndpointProperty].self, from: data).toStringHashableDictionary()
    }

    /// Get the error of the resolved endpoint
    /// - Parameter allocator: The allocator to use for the error
    public func getError() throws -> String? {
        var error = aws_byte_cursor()
        guard aws_endpoints_resolved_endpoint_get_error(rawValue, &error) == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        return error.toString()
    }

    /// Get headers of the resolved endpoint
    /// - Returns: The headers of the resolved endpoint
    /// TODO: refactor
    public func getHeaders() throws -> [String: [String]]? {
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

    deinit {
        aws_endpoints_resolved_endpoint_release(rawValue)
    }
}
