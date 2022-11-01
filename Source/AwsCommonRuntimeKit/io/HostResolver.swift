//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCCommon
import AwsCIo

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
            var options = aws_host_resolver_default_options()
            options.max_entries = maxHosts
            options.el_group = elg.rawValue
            options.shutdown_options = shutdownCallbackCorePointer
            return aws_host_resolver_new_default(allocator.rawValue, &options)
        }) else {
            shutdownCallbackCore.release()
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }

        self.rawValue = rawValue
        self.config = HostResolutionConfig(maxTTL: maxTTL)
    }

    public func resolve(host: String) async throws -> [HostAddress] {
         return try await withCheckedThrowingContinuation({ (continuation: HostResolvedContinuation) in
             HostResolverCore(hostResolver: self, host: host, continuation: continuation, allocator: allocator).retainedResolve()
        })
    }

    deinit {
        aws_host_resolver_release(rawValue)
    }
}
