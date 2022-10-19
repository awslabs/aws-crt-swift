//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCCommon
import AwsCIo

public typealias HostResolvedContinuation = CheckedContinuation<[HostAddress], Error>

public protocol HostResolver: AnyObject {
    var rawValue: UnsafeMutablePointer<aws_host_resolver> { get set }
    var config: UnsafeMutablePointer<aws_host_resolution_config> { get }
    func resolve(host: String) async throws -> [HostAddress]
}

public final class DefaultHostResolver: HostResolver {
    public var rawValue: UnsafeMutablePointer<aws_host_resolver>
    public var config: UnsafeMutablePointer<aws_host_resolution_config>
    private let allocator: Allocator

    public init(eventLoopGroup elg: EventLoopGroup,
                maxHosts: Int,
                maxTTL: Int,
                allocator: Allocator = defaultAllocator,
                shutdownCallback: ShutdownCallback? = nil) throws {
        let shutdownCallbackOptions = ShutdownCallbackOptions(shutdownCallback)
        self.allocator = allocator
        guard let rawValue: UnsafeMutablePointer<aws_host_resolver> = withOptionalUnsafePointer(
                shutdownCallbackOptions?.getCShutdownOptions(), { shutdownOptionsPointer in
            var options = aws_host_resolver_default_options(max_entries: maxHosts,
                    el_group: elg.rawValue,
                    shutdown_options: shutdownOptionsPointer,
                    system_clock_override_fn: nil)
            //TODO: use const in C-IO to avoid mutable pointer here
            return withUnsafeMutablePointer(to: &options) { aws_host_resolver_new_default(allocator.rawValue, $0) }
        }) else {
            shutdownCallbackOptions?.release()
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }

        self.rawValue = rawValue
        let config = aws_host_resolution_config(
            impl: aws_default_dns_resolve,
            max_ttl: maxTTL,
            impl_data: nil
        )

        self.config = fromPointer(ptr: config)

    }

    deinit {
        config.deinitializeAndDeallocate()
        aws_host_resolver_release(rawValue)
    }

    public func resolve(host: String) async throws -> [HostAddress] {
         return try await withCheckedThrowingContinuation({ (continuation: HostResolvedContinuation) in
            resolve(host: host, continuation: continuation)
        })
    }

    private func resolve(host: String, continuation: HostResolvedContinuation) {
        let options = ResolverOptions(resolver: self,
                                      host: AWSString(host, allocator: allocator),
                                      continuation: continuation)
        let pointer: UnsafeMutableRawPointer = fromPointer(ptr: options)

        if (aws_host_resolver_resolve_host(rawValue,
                                       options.host.rawValue,
                                       onHostResolved, config, pointer)) != AWS_OP_SUCCESS {
            continuation.resume(throwing: CommonRunTimeError.crtError(CRTError.makeFromLastError()))
        }
    }
}

private func onHostResolved(_ resolver: UnsafeMutablePointer<aws_host_resolver>!,
                            _ hostName: UnsafePointer<aws_string>!,
                            _ errorCode: Int32,
                            _ hostAddresses: UnsafePointer<aws_array_list>!,
                            _ userData: UnsafeMutableRawPointer!) {
    let options = userData.assumingMemoryBound(to: ResolverOptions.self)

    let length = aws_array_list_length(hostAddresses)
    var addresses: [HostAddress] = Array(repeating: HostAddress(), count: length)

    for index in 0..<length {
        var address: UnsafeMutableRawPointer! = nil
        aws_array_list_get_at_ptr(hostAddresses, &address, index)
        let hostAddressCType = address.bindMemory(to: aws_host_address.self, capacity: 1).pointee
        let hostAddress = HostAddress(hostAddress: hostAddressCType)
        addresses[index] = hostAddress
    }

    if errorCode == 0 {
        options.pointee.continuation.resume(returning: addresses)
    } else {
        options.pointee.continuation.resume(throwing: CRTError(errorCode: errorCode))
    }
    options.deinitializeAndDeallocate()
}
