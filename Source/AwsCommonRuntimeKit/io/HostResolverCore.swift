//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCIo

class HostResolverCore {
    let host: AWSString
    let hostResolver: HostResolver
    let continuation: HostResolvedContinuation

    init(resolver: HostResolver, host: String, continuation: HostResolvedContinuation, allocator: Allocator) {
        self.host = AWSString(host, allocator: allocator)
        self.continuation = continuation
        self.hostResolver = resolver
    }

    private func getRetainedSelf() -> UnsafeMutableRawPointer {
        return Unmanaged<HostResolverCore>.passRetained(self).toOpaque()
    }

    /// This function does a manual retain on HostResolverCore
    /// to keep it until until onHostResolved callback has fired which will do the release.
    func retainedResolve() {
        if aws_host_resolver_resolve_host(hostResolver.rawValue,
                                          host.rawValue,
                                          onHostResolved,
                                          hostResolver.config.rawValue,
                                          getRetainedSelf()) != AWS_OP_SUCCESS {
            //TODO: this is wrong. Sometimes it triggers the error callback and sometimes it doesn't.
            //I have a fix in progress.
            release()
            continuation.resume(throwing: CommonRunTimeError.crtError(CRTError.makeFromLastError()))
        }
    }

    private func release() {
        Unmanaged.passUnretained(self).release()
    }
}

func onHostResolved(_ resolver: UnsafeMutablePointer<aws_host_resolver>!,
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
