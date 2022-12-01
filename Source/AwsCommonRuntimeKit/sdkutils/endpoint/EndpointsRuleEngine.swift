//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCSdkUtils
import Foundation

/// Rule engine for matching endpoint rules
public class EndpointsRuleEngine {

    let rawValue: OpaquePointer

    /// Initialize a new rule engine
    /// - Parameters:
    ///   - partitions: JSON string containing partition data
    ///   - ruleSet: The rule set string to use for the rule engine
    ///   - allocator: The allocator to use for creating rule engine
    public init(partitions: String, ruleSet: String, allocator: Allocator = defaultAllocator) throws {
        let getRawValue: () throws -> OpaquePointer = {
            guard let partitions = (partitions.withByteCursor { partitionsCursor in
                aws_partitions_config_new_from_string(allocator.rawValue, partitionsCursor)
            }) else {
                throw CommonRunTimeError.crtError(.makeFromLastError())
            }
            defer {
                aws_partitions_config_release(partitions)
            }

            guard let ruleSet = (ruleSet.withByteCursor { ruleSetCursor in
                aws_endpoints_ruleset_new_from_string(allocator.rawValue, ruleSetCursor)
            }) else {
                throw CommonRunTimeError.crtError(.makeFromLastError())
            }
            defer {
                aws_endpoints_ruleset_release(ruleSet)
            }

            guard let rawValue = aws_endpoints_rule_engine_new(allocator.rawValue, ruleSet, partitions) else {
                throw CommonRunTimeError.crtError(.makeFromLastError())
            }
            return rawValue
        }

        self.rawValue = try getRawValue()
    }

    /// Resolve an endpoint from the rule engine using the provided request context
    /// - Parameter context: The request context to use for endpoint resolution
    /// - Returns: The resolved endpoint
    public func resolve(context: CRTAWSEndpointsRequestContext) throws -> ResolvedEndpoint {
        var resolvedEndpoint: OpaquePointer! = nil
        guard aws_endpoints_rule_engine_resolve(rawValue, context.rawValue, &resolvedEndpoint)
                == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        defer {
            aws_endpoints_resolved_endpoint_release(resolvedEndpoint)
        }

        let type = aws_endpoints_resolved_endpoint_get_type(resolvedEndpoint)

        if type == AWS_ENDPOINTS_RESOLVED_ENDPOINT {
            return ResolvedEndpoint.endpoint(
                    url: try getURL(rawValue: resolvedEndpoint),
                    headers: try getHeaders(rawValue: resolvedEndpoint),
                    properties: try getProperties(rawValue: resolvedEndpoint))
        } else {
            return ResolvedEndpoint.error(message: try getErrorMessage(rawValue: resolvedEndpoint))
        }

    }

    /// Get the URL of the resolved endpoint
    /// - Returns: The URL of the resolved endpoint
    func getURL(rawValue: OpaquePointer) throws -> String {
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
    public func getHeaders(rawValue: OpaquePointer) throws -> [String: [String]] {
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
    func getProperties(rawValue: OpaquePointer) throws -> [String: AnyHashable] {
        var properties = aws_byte_cursor()
        guard aws_endpoints_resolved_endpoint_get_properties(rawValue, &properties) == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        guard properties.len > 0 else {
            return [String: AnyHashable]()
        }
        let data = Data(bytes: properties.ptr, count: properties.len)
        return try JSONDecoder().decode([String: EndpointProperty].self, from: data).toStringHashableDictionary()
    }

    /// Get the error of the resolved endpoint
    /// - Returns: The error message of the resolved endpoint
    func getErrorMessage(rawValue: OpaquePointer) throws -> String {
        var error = aws_byte_cursor()
        guard aws_endpoints_resolved_endpoint_get_error(rawValue, &error) == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        return error.toString()
    }

    deinit {
        aws_endpoints_rule_engine_release(rawValue)
    }
}
