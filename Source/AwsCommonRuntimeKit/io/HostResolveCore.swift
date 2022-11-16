//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCIo

typealias HostResolvedContinuation = CheckedContinuation<[HostAddress], Error>

/// Core classes have manual memory management.
/// You have to balance the retain & release calls in all cases to avoid leaking memory.
class HostResolveCore {
    let continuation: HostResolvedContinuation

    init(_ continuation: HostResolvedContinuation) {
        self.continuation = continuation
    }

    private func getRetainedSelf() -> UnsafeMutableRawPointer {
        return Unmanaged<HostResolveCore>.passRetained(self).toOpaque()
    }

    /// This function does a manual retain on HostResolverCore
    /// to keep it until until onHostResolved callback has fired which will do the release.
    static func retainedResolve(hostResolver: HostResolver, host: String, continuation: HostResolvedContinuation, allocator: Allocator) {
        let core = HostResolveCore(continuation)
        let hostStr = AWSString(host, allocator: allocator)
        let retainedSelf = core.getRetainedSelf()
        withUnsafePointer(to: hostResolver.getHostResolutionConfig()) { hostResolutionConfigPointer in
            if aws_host_resolver_resolve_host(hostResolver.rawValue,
                    hostStr.rawValue,
                    onHostResolved,
                    hostResolutionConfigPointer,
                    retainedSelf) != AWS_OP_SUCCESS {
                //TODO: this is wrong. Sometimes it triggers the error callback and sometimes it doesn't.
                // I have a fix in progress in aws-c-io
                core.release()
                continuation.resume(throwing: CommonRunTimeError.crtError(CRTError.makeFromLastError()))
            }
        }
    }

    private func release() {
        Unmanaged.passUnretained(self).release()
    }
}

private func onHostResolved(_ resolver: UnsafeMutablePointer<aws_host_resolver>?,
                            _ hostName: UnsafePointer<aws_string>?,
                            _ errorCode: Int32,
                            _ hostAddresses: UnsafePointer<aws_array_list>?,
                            _ userData: UnsafeMutableRawPointer!) {
    let hostResolverCore = Unmanaged<HostResolveCore>.fromOpaque(userData).takeRetainedValue()
    if errorCode != AWS_OP_SUCCESS {
        hostResolverCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
        return
    }

    // Success
    let length = aws_array_list_length(hostAddresses!)
    var addresses = [HostAddress]()

    for index in 0..<length {
        var address: UnsafeMutableRawPointer! = nil
        aws_array_list_get_at_ptr(hostAddresses!, &address, index)
        let hostAddressCType = address.bindMemory(to: aws_host_address.self, capacity: 1).pointee
        addresses.append(HostAddress(hostAddress: hostAddressCType))
    }

    hostResolverCore.continuation.resume(returning: addresses)
}
