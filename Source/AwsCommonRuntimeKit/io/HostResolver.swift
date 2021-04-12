//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCCommon
import AwsCIo

public typealias HostAddress = aws_host_address
public typealias OnHostResolved = (HostResolver, [HostAddress], CRTError) -> Void

public protocol HostResolver: class {
    var rawValue: UnsafeMutablePointer<aws_host_resolver> { get set }
    var config: UnsafeMutablePointer<aws_host_resolution_config> { get }
    func resolve(host: String, onResolved: @escaping OnHostResolved) throws
}

public final class DefaultHostResolver: HostResolver {
    public var rawValue: UnsafeMutablePointer<aws_host_resolver>
    public var config: UnsafeMutablePointer<aws_host_resolution_config>
    private let allocator: Allocator
    public let shutDownOptions: ShutDownCallbackOptions?

    public init(eventLoopGroup elg: EventLoopGroup,
                maxHosts: Int,
                maxTTL: Int,
                allocator: Allocator = defaultAllocator,
                shutDownOptions: ShutDownCallbackOptions? = nil) {
        self.allocator = allocator

        var ptr: UnsafePointer<aws_shutdown_callback_options>?
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

            ptr = UnsafePointer(mutablePtr)

        defer {ptr?.deallocate()}
        }
        self.shutDownOptions = shutDownOptions
        var options = aws_host_resolver_default_options(max_entries: maxHosts, el_group: elg.rawValue, shutdown_options: ptr, system_clock_override_fn: nil)
        self.rawValue = aws_host_resolver_new_default(allocator.rawValue, &options)

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
        aws_host_resolver_release(rawValue)
        if let shutDownOptions = shutDownOptions {
            shutDownOptions.semaphore.wait()
        }
    }

    public func resolve(host: String, onResolved callback: @escaping OnHostResolved) throws {
        let options = ResolverOptions(resolver: self,
                                      host: AWSString(host, allocator: self.allocator),
                                      onResolved: callback)
        let unmanagedOptions = Unmanaged.passRetained(options)

        if aws_host_resolver_resolve_host(self.rawValue,
                                          options.host.rawValue,
                                          onHostResolved,
                                          self.config,
                                          unmanagedOptions.toOpaque()) != AWS_OP_SUCCESS {
            // We have an unbalanced retain on unmanagedOptions, need to release it!
            defer { unmanagedOptions.release() }
            throw AWSCommonRuntimeError()
        }
    }
}

private func onHostResolved(_ resolver: UnsafeMutablePointer<aws_host_resolver>!,
                            _ hostName: UnsafePointer<aws_string>!,
                            _ errorCode: Int32,
                            _ hostAddresses: UnsafePointer<aws_array_list>!,
                            _ userData: UnsafeMutableRawPointer!) {
    // Consumes the unbalanced retain that was made to get the value here
    let options: ResolverOptions = Unmanaged.fromOpaque(userData).takeRetainedValue()

    let length = aws_array_list_length(hostAddresses)
    var addresses: [HostAddress] = Array(repeating: HostAddress(), count: length)

    for index  in 0..<length {
        var address: UnsafeMutableRawPointer! = nil
        aws_array_list_get_at_ptr(hostAddresses, &address, index)
        addresses[index] = address.bindMemory(to: HostAddress.self, capacity: 1).pointee
    }

    let error = AWSError(errorCode: errorCode)
    options.onResolved(options.resolver, addresses, CRTError.crtError(error))
}
