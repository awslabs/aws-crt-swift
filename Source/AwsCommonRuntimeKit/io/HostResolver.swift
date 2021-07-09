//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCCommon
import AwsCIo

public typealias HostAddress = aws_host_address
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
    public let shutDownOptions: ShutDownCallbackOptions?
    var shutdownCallbackOptionPtr: UnsafePointer<aws_shutdown_callback_options>?
    let hostResolverOptionsPtr = UnsafeMutablePointer<aws_host_resolver_default_options>.allocate(capacity: 1)

    public init(eventLoopGroup elg: EventLoopGroup,
                maxHosts: Int,
                maxTTL: Int,
                allocator: Allocator = defaultAllocator,
                shutDownOptions: ShutDownCallbackOptions? = nil) {
        self.allocator = allocator

        if let shutDownOptions = shutDownOptions {
            let shutDownPtr = UnsafeMutablePointer<ShutDownCallbackOptions>.allocate(capacity: 1)
            shutDownPtr.initialize(to: shutDownOptions)
            let options = aws_shutdown_callback_options(shutdown_callback_fn: { (userData) in
                guard let userdata = userData else {
                    return
                }
                let pointer = userdata.assumingMemoryBound(to: ShutDownCallbackOptions.self)
                defer { pointer.deinitializeAndDeallocate() }
                pointer.pointee.shutDownCallback(pointer.pointee.semaphore)
            }, shutdown_callback_user_data: shutDownPtr)

            let mutablePtr = UnsafeMutablePointer<aws_shutdown_callback_options>.allocate(capacity: 1)
            mutablePtr.initialize(to: options)

            shutdownCallbackOptionPtr = UnsafePointer(mutablePtr)
        }
        self.shutDownOptions = shutDownOptions
        let options = aws_host_resolver_default_options(max_entries: maxHosts,
                                                        el_group: elg.rawValue,
                                                        shutdown_options: shutdownCallbackOptionPtr,
                                                        system_clock_override_fn: nil)
        hostResolverOptionsPtr.initialize(to: options)
        self.rawValue = aws_host_resolver_new_default(allocator.rawValue, hostResolverOptionsPtr)

        let config = aws_host_resolution_config(
            impl: aws_default_dns_resolve,
            max_ttl: maxTTL,
            impl_data: nil
        )

        let hostResolverConfigPointer = UnsafeMutablePointer<aws_host_resolution_config>.allocate(capacity: 1)
        hostResolverConfigPointer.initialize(to: config)
        self.config = hostResolverConfigPointer

    }

    deinit {
        config.deinitializeAndDeallocate()
        hostResolverOptionsPtr.deinitializeAndDeallocate()
        aws_host_resolver_release(rawValue)
        if let shutDownOptions = shutDownOptions {
            shutDownOptions.semaphore.wait()
            shutdownCallbackOptionPtr?.deallocate()
        }
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
        let ptr = UnsafeMutablePointer<ResolverOptions>.allocate(capacity: 1)
        ptr.initialize(to: options)
        
        aws_host_resolver_resolve_host(rawValue,
                                       options.host.rawValue,
                                       { hostResolver, hostName, errorCode, hostAddresses, userData in
            guard let userData = userData else {
                return
            }
            let optionsPtr = userData.assumingMemoryBound(to: ResolverOptions.self)
            defer {optionsPtr.deinitializeAndDeallocate()}

            let length = aws_array_list_length(hostAddresses)
            var addresses: [HostAddress] = Array(repeating: HostAddress(), count: length)

            for index  in 0..<length {
                var address: UnsafeMutableRawPointer! = nil
                aws_array_list_get_at_ptr(hostAddresses, &address, index)
                addresses[index] = address.bindMemory(to: HostAddress.self, capacity: 1).pointee
            }
            if errorCode == 0 {
                optionsPtr.pointee.continuation.resume(returning: addresses)
            } else {
                let error = AWSError(errorCode: errorCode)
                optionsPtr.pointee.continuation.resume(throwing: CRTError.crtError(error))
            }
        }, config, ptr)

    }
}

