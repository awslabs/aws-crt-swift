//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCCommon
import AwsCIo

public typealias HostAddress = aws_host_address
public typealias OnHostResolved = (HostResolver, [HostAddress], CRTError) -> Void

public protocol HostResolver: AnyObject {
    var rawValue: UnsafeMutablePointer<aws_host_resolver> { get set }
    var config: UnsafeMutablePointer<aws_host_resolution_config> { get }
    func resolve(host: String, onResolved: @escaping OnHostResolved) throws
}

public final class DefaultHostResolver: HostResolver {
    public var rawValue: UnsafeMutablePointer<aws_host_resolver>
    public var config: UnsafeMutablePointer<aws_host_resolution_config>
    private let allocator: Allocator
    public let shutDownOptions: ShutDownCallbackOptions?
    var shutdownCallbackOptionPtr: UnsafePointer<aws_shutdown_callback_options>?
    let hostResolverOptionsPtr: UnsafeMutablePointer<aws_host_resolver_default_options>

    public init(eventLoopGroup elg: EventLoopGroup,
                maxHosts: Int,
                maxTTL: Int,
                allocator: Allocator = defaultAllocator,
                shutDownOptions: ShutDownCallbackOptions? = nil) {
        self.allocator = allocator

        let shutdownCallbackOptionPtr = shutDownOptions?.toShutDownCPointer()

        self.shutDownOptions = shutDownOptions
        let options = aws_host_resolver_default_options(max_entries: maxHosts,
                                                        el_group: elg.rawValue,
                                                        shutdown_options: shutdownCallbackOptionPtr,
                                                        system_clock_override_fn: nil)
        self.hostResolverOptionsPtr = fromPointer(ptr: options)
        self.rawValue = aws_host_resolver_new_default(allocator.rawValue, hostResolverOptionsPtr)

        let config = aws_host_resolution_config(
            impl: aws_default_dns_resolve,
            max_ttl: maxTTL,
            impl_data: nil
        )

        self.config = fromPointer(ptr: config)

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

    public func resolve(host: String, onResolved callback: @escaping OnHostResolved) throws {
        let options = ResolverOptions(resolver: self,
                                      host: AWSString(host, allocator: self.allocator),
                                      onResolved: callback)
        let pointer: UnsafeMutableRawPointer = fromPointer(ptr: options)

        if aws_host_resolver_resolve_host(self.rawValue,
                                          options.host.rawValue,
                                          onHostResolved,
                                          self.config,
                                          pointer) != AWS_OP_SUCCESS {
            pointer.deallocate()
            throw AWSCommonRuntimeError()
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

    for index  in 0..<length {
        var address: UnsafeMutableRawPointer! = nil
        aws_array_list_get_at_ptr(hostAddresses, &address, index)
        addresses[index] = address.bindMemory(to: HostAddress.self, capacity: 1).pointee
    }

    let error = AWSError(errorCode: errorCode)

    options.pointee.onResolved(options.pointee.resolver, addresses, CRTError.crtError(error))
    options.deinitializeAndDeallocate()
}
