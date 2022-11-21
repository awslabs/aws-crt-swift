//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCSdkUtils

/// Rule engine for matching endpoint rules
public class CRTAWSEndpointsRuleEngine {

    let rawValue: OpaquePointer
    let allocator: Allocator

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

            guard let ruleSet = (ruleSet.withByteCursor { ruleSetCursor in
                aws_endpoints_ruleset_new_from_string(allocator.rawValue, ruleSetCursor)
            }) else {
                throw CommonRunTimeError.crtError(.makeFromLastError())
            }

            defer {
                aws_partitions_config_release(partitions)
                aws_endpoints_ruleset_release(ruleSet)
            }

            guard let rawValue = aws_endpoints_rule_engine_new(allocator.rawValue, ruleSet, partitions) else {
                throw CommonRunTimeError.crtError(.makeFromLastError())
            }

            return rawValue
        }
        self.allocator = allocator
        self.rawValue = try getRawValue()

    }

    /// Resolve an endpoint from the rule engine using the provided request context
    /// - Parameter context: The request context to use for endpoint resolution
    /// - Returns: The resolved endpoint
    public func resolve(context: CRTAWSEndpointsRequestContext) throws -> CRTAWSEndpointResolvedEndpoint? {
        let resolvedEndpoint: UnsafeMutablePointer<OpaquePointer?> = allocator.allocate(capacity: 1)
        defer {
            allocator.release(resolvedEndpoint)
        }
        guard aws_endpoints_rule_engine_resolve(rawValue, context.rawValue, resolvedEndpoint)
                == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }

        guard let rawResolvedEndpoint = resolvedEndpoint.pointee else {
            return nil
        }
        return CRTAWSEndpointResolvedEndpoint(rawValue: rawResolvedEndpoint)
    }

    deinit {
        aws_endpoints_rule_engine_release(rawValue)
    }
}
