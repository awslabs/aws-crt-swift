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
             hostResolverCore.retainedResolve(hostResolver: self)
        })
    }
}

//TODO: make it consistent by creating a separate class (maybe) and retain/release function.
private class HostResolverCore {
    let host: AWSString
    let resolver: HostResolver
    let continuation: HostResolvedContinuation

    init(resolver: HostResolver, host: String, continuation: HostResolvedContinuation, allocator: Allocator) {
        self.host = AWSString(host, allocator: allocator)
        self.continuation = continuation
        self.resolver = resolver
    }

    /// This function does a manual retain on HostResolverCore
    /// to keep it until until onHostResolved callback has fired which will do the release.
    func retainedResolve(hostResolver: HostResolver) {
        let retainedHostResolverCore = Unmanaged<HostResolverCore>.passRetained(self).toOpaque()
        if aws_host_resolver_resolve_host(hostResolver.rawValue,
                                          host.rawValue,
                                          onHostResolved,
                                          hostResolver.config.rawValue,
                                          retainedHostResolverCore) != AWS_OP_SUCCESS {
            //TODO: this is wrong. I need to learn more about this. Sometimes it triggers the error callback and
            // sometimes it doesn't.
            Unmanaged.passUnretained(self).release()
            continuation.resume(throwing: CommonRunTimeError.crtError(CRTError.makeFromLastError()))
        }
    }
}

private func onHostResolved(_ resolver: UnsafeMutablePointer<aws_host_resolver>!,
                            _ hostName: UnsafePointer<aws_string>!,
                            _ errorCode: Int32,
                            _ hostAddresses: UnsafePointer<aws_array_list>!,
                            _ userData: UnsafeMutableRawPointer!) {
    let userData = Unmanaged<HostResolverCore>.fromOpaque(userData).takeRetainedValue()
    if errorCode != AWS_OP_SUCCESS {
        userData.continuation.resume(throwing: CRTError(code: errorCode))
        return
    }
    let length = aws_array_list_length(hostAddresses)
    var addresses: [HostAddress] = Array(repeating: HostAddress(), count: length)

    for index in 0..<length {
        var address: UnsafeMutableRawPointer! = nil
        aws_array_list_get_at_ptr(hostAddresses, &address, index)
        let hostAddressCType = address.bindMemory(to: aws_host_address.self, capacity: 1).pointee
        let hostAddress = HostAddress(hostAddress: hostAddressCType)
        addresses[index] = hostAddress
    }

    userData.continuation.resume(returning: addresses)
}
