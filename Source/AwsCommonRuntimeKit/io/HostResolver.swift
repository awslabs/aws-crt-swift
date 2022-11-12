//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCCommon
import AwsCIo

public class HostResolver {
    let rawValue: UnsafeMutablePointer<aws_host_resolver>
    let maxTTL: Int
    private let allocator: Allocator

    public static func makeDefault(eventLoopGroup: EventLoopGroup,
                                   maxHosts: Int,
                                   maxTTL: Int,
                                   allocator: Allocator = defaultAllocator,
                                   shutdownCallback: ShutdownCallback? = nil) throws -> HostResolver {
        try HostResolver(eventLoopGroup: eventLoopGroup, maxHosts: maxHosts, maxTTL: maxTTL, allocator: allocator, shutdownCallback: shutdownCallback)
    }

    init(eventLoopGroup: EventLoopGroup,
         maxHosts: Int,
         maxTTL: Int,
         allocator: Allocator = defaultAllocator,
         shutdownCallback: ShutdownCallback? = nil) throws {
        self.allocator = allocator
        let shutdownCallbackCore = ShutdownCallbackCore(shutdownCallback)
        guard let rawValue: UnsafeMutablePointer<aws_host_resolver> = withUnsafePointer(
                to: shutdownCallbackCore.getRetainedShutdownOptions(), { shutdownCallbackCorePointer in
            var options = aws_host_resolver_default_options()
            options.max_entries = maxHosts
            options.el_group = eventLoopGroup.rawValue
            options.shutdown_options = shutdownCallbackCorePointer
            return aws_host_resolver_new_default(allocator.rawValue, &options)
        }) else {
            shutdownCallbackCore.release()
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        self.rawValue = rawValue
        self.maxTTL = maxTTL
    }

    public func resolve(host: String) async throws -> [HostAddress] {
        return try await withCheckedThrowingContinuation({ (continuation: HostResolvedContinuation) in
            HostResolveCore(hostResolver: self, host: host, continuation: continuation, allocator: allocator).retainedResolve()
        })
    }

    func getHostResolutionConfig() -> aws_host_resolution_config {
        var cHostResolutionConfig = aws_host_resolution_config()
        cHostResolutionConfig.max_ttl = maxTTL
        cHostResolutionConfig.impl = aws_default_dns_resolve
        return cHostResolutionConfig
    }

    deinit {
        aws_host_resolver_release(rawValue)
    }
}
