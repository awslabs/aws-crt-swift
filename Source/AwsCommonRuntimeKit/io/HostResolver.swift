//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCCommon
import AwsCIo

typealias HostResolvedContinuation = CheckedContinuation<[HostAddress], Error>

public class HostResolver {
    let rawValue: UnsafeMutablePointer<aws_host_resolver>
    let config: HostResolutionConfig
    private let allocator: Allocator

    public init(eventLoopGroup elg: EventLoopGroup,
                maxHosts: Int,
                maxTTL: Int,
                allocator: Allocator = defaultAllocator,
                shutdownCallback: ShutdownCallback? = nil) throws {
        let shutdownCallbackCore = ShutdownCallbackCore(shutdownCallback)
        self.allocator = allocator
        guard let rawValue: UnsafeMutablePointer<aws_host_resolver> = withUnsafePointer(
                to: shutdownCallbackCore.getRetainedShutdownOptions(), { shutdownCallbackCorePointer in
            var options = aws_host_resolver_default_options(max_entries: maxHosts,
                    el_group: elg.rawValue,
                    shutdown_options: shutdownCallbackCorePointer,
                    system_clock_override_fn: nil)
            //TODO: use const in C-IO to avoid mutable pointer here
            return withUnsafeMutablePointer(to: &options) { aws_host_resolver_new_default(allocator.rawValue, $0) }
        }) else {
            shutdownCallbackCore.release()
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }

        self.rawValue = rawValue
        self.config = HostResolutionConfig(maxTTL: maxTTL)
    }

    deinit {
        aws_host_resolver_release(rawValue)
    }

    public func resolve(host: String) async throws -> [HostAddress] {
         return try await withCheckedThrowingContinuation({ (continuation: HostResolvedContinuation) in
             let hostResolverCore = HostResolverCore(resolver: self, host: host, continuation: continuation, allocator: allocator)
             hostResolverCore.retainedResolve()
        })
    }
}
