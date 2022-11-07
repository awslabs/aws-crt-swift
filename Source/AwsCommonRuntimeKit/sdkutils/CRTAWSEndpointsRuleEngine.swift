//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCSdkUtils

/// Rule engine for matching endpoint rules
public class CRTAWSEndpointsRuleEngine {
    let partitions: UnsafeMutablePointer<aws_partitions_config>
    let ruleSet: UnsafeMutablePointer<aws_endpoints_ruleset>
    let rawValue: OpaquePointer

    /// Initialize a new rule engine
    /// - Parameters:
    ///   - partitions: JSON string containing partition data
    ///   - ruleSet: The rule set string to use for the rule engine
    ///   - allocator: The allocator to use for creating rule engine
    public init(partitions: String, ruleSet: String, allocator: Allocator = defaultAllocator) throws {
        guard
            let partitions = aws_partitions_config_new_from_string(
                allocator.rawValue,
                partitions.newByteCursor().rawValue
            ),
            let ruleSet = aws_endpoints_ruleset_new_from_string(allocator.rawValue, ruleSet.newByteCursor().rawValue),
            let rawValue = aws_endpoints_rule_engine_new(allocator.rawValue, ruleSet, partitions)
        else { throw CRTError.crtError(AWSError.makeFromLastError()) }

        self.partitions = partitions
        self.ruleSet = ruleSet
        self.rawValue = rawValue
    }

    /// Resolve an endpoint from the rule engine using the provided request context
    /// - Parameter context: The request context to use for endpoint resolution
    /// - Returns: The resolved endpoint
    public func resolve(context: CRTAWSEndpointsRequestContext) throws -> CRTAWSEndpointResolvedEndpoint? {
        let resolvedEndpoint: UnsafeMutablePointer<OpaquePointer?>? = UnsafeMutablePointer.allocate(capacity: 1)
        defer {
            resolvedEndpoint?.deallocate()
        }
        let success = aws_endpoints_rule_engine_resolve(rawValue, context.rawValue, resolvedEndpoint)
        if success != 0 {
            throw CRTError.crtError(AWSError.makeFromLastError())
        }

        guard let pointee = resolvedEndpoint?.pointee else {
            return nil
        }

        return CRTAWSEndpointResolvedEndpoint(rawValue: pointee)
    }

    deinit {
        aws_partitions_config_release(partitions)
        aws_endpoints_rule_engine_release(rawValue)
        aws_endpoints_ruleset_release(ruleSet)
    }
}
