//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCCommon
import AwsCIo

public class HostResolver {
    let rawValue: UnsafeMutablePointer<aws_host_resolver>
    let maxTTL: Int
    private let allocator: Allocator

    public static func makeDefault(eventLoopGroup: EventLoopGroup,
                                   maxHosts: Int = 16,
                                   maxTTL: Int = 30,
                                   allocator: Allocator = defaultAllocator,
                                   shutdownCallback: ShutdownCallback? = nil) throws -> HostResolver {
        try HostResolver(
            eventLoopGroup: eventLoopGroup,
            maxHosts: maxHosts,
            maxTTL: maxTTL,
            allocator: allocator,
            shutdownCallback: shutdownCallback)
    }

    init(eventLoopGroup: EventLoopGroup,
         maxHosts: Int,
         maxTTL: Int,
         allocator: Allocator = defaultAllocator,
         shutdownCallback: ShutdownCallback? = nil) throws {
        self.allocator = allocator
        let shutdownCallbackCore = ShutdownCallbackCore(shutdownCallback)
        let getRawValue: () -> UnsafeMutablePointer<aws_host_resolver>? = {
            withUnsafePointer(to: shutdownCallbackCore.getRetainedShutdownOptions()) { shutdownCallbackCorePointer in
                var options = aws_host_resolver_default_options()
                options.max_entries = maxHosts
                options.el_group = eventLoopGroup.rawValue
                options.shutdown_options = shutdownCallbackCorePointer
                return aws_host_resolver_new_default(allocator.rawValue, &options)
            }
        }

        guard let rawValue = getRawValue() else {
            shutdownCallbackCore.release()
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        self.rawValue = rawValue
        self.maxTTL = maxTTL
    }

    public func resolve(host: String) async throws -> [HostAddress] {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<[HostAddress], Error>) in
            let continuationCore = ContinuationCore(continuation: continuation)
            let hostStr = AWSString(host, allocator: allocator)
            withUnsafePointer(to: getHostResolutionConfig()) { hostResolutionConfigPointer in
                if aws_host_resolver_resolve_host(rawValue,
                                                  hostStr.rawValue,
                                                  onHostResolved,
                                                  hostResolutionConfigPointer,
                                                  continuationCore.passRetained()) != AWS_OP_SUCCESS {
                    // TODO: this is wrong. Sometimes it triggers the error callback and sometimes it doesn't.
                    // I have a fix in progress in aws-c-io
                    continuationCore.release()
                    continuation.resume(throwing: CommonRunTimeError.crtError(CRTError.makeFromLastError()))
                }
            }
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

private func onHostResolved(_ resolver: UnsafeMutablePointer<aws_host_resolver>?,
                            _ hostName: UnsafePointer<aws_string>?,
                            _ errorCode: Int32,
                            _ hostAddresses: UnsafePointer<aws_array_list>?,
                            _ userData: UnsafeMutableRawPointer!) {
    let hostResolverCore = Unmanaged<ContinuationCore<[HostAddress]>>.fromOpaque(userData).takeRetainedValue()
    guard errorCode == AWS_OP_SUCCESS else {
        hostResolverCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
        return
    }

    // Success
    let length = aws_array_list_length(hostAddresses!)
    let addresses = (0..<length).map { index -> HostAddress in
        var address: UnsafeMutableRawPointer! = nil
        aws_array_list_get_at_ptr(hostAddresses!, &address, index)
        let hostAddressCType = address.bindMemory(to: aws_host_address.self, capacity: 1).pointee
        return HostAddress(hostAddress: hostAddressCType)
    }

    hostResolverCore.continuation.resume(returning: addresses)
}
