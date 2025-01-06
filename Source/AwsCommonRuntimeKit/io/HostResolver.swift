//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCCommon
import AwsCIo

/// All host resolver implementation must conform to this protocol.
public protocol HostResolverProtocol {
    /// Resolves the address(es) for HostResolverArguments and returns a list of
    /// addresses with (most likely) two addresses, one AAAA and one A.
    /// - Parameter args: The host name to resolve address for.
    /// - Returns: List of resolved host addresses.
    /// - Throws: CommonRunTimeError.crtError
    func resolveAddress(args: HostResolverArguments) async throws -> [HostAddress]
    /// Reports a failure on an address so that the background cache can accommodate
    /// the failure and likely not return the address until it recovers.
    /// - Parameter address: The address to report the failure for.
    func reportFailureOnAddress(address: HostAddress)
    /// Empties the cache for an address.
    /// - Parameter args: The host name to purge the cache.
    func purgeCache(args: HostResolverArguments) async
    /// Empties the cache for all addresses.
    func purgeCache() async
}

// Swift cannot verify the sendability due to a pointer, and thread safety is handled in the C layer.
// So mark it as unchecked Sendable.
/// CRT Host Resolver which performs async DNS lookups
public class HostResolver: HostResolverProtocol, @unchecked Sendable {
    let rawValue: UnsafeMutablePointer<aws_host_resolver>
    let maxTTL: Int

    /// Creates a host resolver with the default behavior.
    public static func makeDefault(eventLoopGroup: EventLoopGroup,
                                   maxHosts: Int = 16,
                                   maxTTL: Int = 30,
                                   shutdownCallback: ShutdownCallback? = nil) throws -> HostResolver {
        try HostResolver(
            eventLoopGroup: eventLoopGroup,
            maxHosts: maxHosts,
            maxTTL: maxTTL,
            shutdownCallback: shutdownCallback)
    }

    init(eventLoopGroup: EventLoopGroup,
         maxHosts: Int,
         maxTTL: Int,
         shutdownCallback: ShutdownCallback? = nil) throws {
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

    /// Resolves the address(es) for HostResolverArguments and returns a list of
    /// addresses with (most likely) two addresses, one AAAA and one A.
    /// - Parameter args: The host name to resolve address for.
    /// - Returns: List of resolved host addresses.
    /// - Throws: CommonRunTimeError.crtError
    public func resolveAddress(args: HostResolverArguments) async throws -> [HostAddress] {
        let host = args.hostName
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<[HostAddress], Error>) in
            let continuationCore = ContinuationCore(continuation: continuation)
            let hostStr = AWSString(host)
            withUnsafePointer(to: getHostResolutionConfig()) { hostResolutionConfigPointer in
                if aws_host_resolver_resolve_host(
                    rawValue,
                    hostStr.rawValue,
                    onHostResolved,
                    hostResolutionConfigPointer,
                    continuationCore.passRetained()
                ) != AWS_OP_SUCCESS {
                    continuationCore.release()
                    continuation.resume(throwing: CommonRunTimeError.crtError(CRTError.makeFromLastError()))
                }
            }
        })
    }

    /// Reports a failure on an address so that the background cache can accommodate
    /// the failure and likely not return the address until it recovers.
    /// Note: While the underlying C API may report an error, we ignore it because users don't care and
    /// don't have a good way to deal with it.
    /// - Parameter address: The address to report the failure for.
    public func reportFailureOnAddress(address: HostAddress) {
        address.withCPointer { cAddress in
            _ = aws_host_resolver_record_connection_failure(rawValue, cAddress)
        }
    }

    /// Purges the cache for a specific address
    /// Note: While the underlying C API may report an error, we ignore it because users don't care and
    /// don't have a good way to deal with it.
    /// - Parameter args: The host name to purge the cache.
    public func purgeCache(args: HostResolverArguments) async {
        let host = AWSString(args.hostName)
        return await withCheckedContinuation({ (continuation: CheckedContinuation<(), Never>) in
            let continuationCore = Box(continuation)
            var purgeCacheOptions = aws_host_resolver_purge_host_options()
            purgeCacheOptions.host = UnsafePointer(host.rawValue)
            purgeCacheOptions.on_host_purge_complete_callback = onPurgeCacheComplete
            purgeCacheOptions.user_data = continuationCore.passRetained()
            guard aws_host_resolver_purge_host_cache(rawValue, &purgeCacheOptions) == AWS_OP_SUCCESS else {
                continuationCore.release()
                continuation.resume()
                return
            }
        })
    }

    /// Wipe out anything cached by resolver.
    /// Note: While the underlying C API may report an error, we ignore it because users don't care and
    /// don't have a good way to deal with it.
    public func purgeCache() async {
        await withCheckedContinuation({ (continuation: CheckedContinuation<(), Never>) in
            let continuationCore = Box(continuation)
            guard aws_host_resolver_purge_cache_with_callback(
                    rawValue,
                    onPurgeCacheComplete,
                    continuationCore.passRetained()) == AWS_OP_SUCCESS
            else {
                continuationCore.release()
                continuation.resume()
                return
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

private func onPurgeCacheComplete(_ userData: UnsafeMutableRawPointer!) {
    let continuationCore = Unmanaged<Box<CheckedContinuation<(), Never>>>
        .fromOpaque(userData)
        .takeRetainedValue()
    continuationCore.contents.resume()
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
