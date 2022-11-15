//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth

typealias CredentialsContinuation = CheckedContinuation<CRTCredentials, Error>

/// Core classes have manual memory management.
/// You have to balance the retain & release calls in all cases to avoid leaking memory.
class GetCredentialsCore {
    var continuation: CredentialsContinuation

    init(continuation: CredentialsContinuation) {
        self.continuation = continuation
    }

    private func getRetainedSelf() -> UnsafeMutableRawPointer {
        return Unmanaged<GetCredentialsCore>.passRetained(self).toOpaque()
    }

    static func getRetainedCredentials(credentialProvider: CredentialsProvider, continuation: CredentialsContinuation) {
        let core = GetCredentialsCore(continuation: continuation)
        let retainedSelf = core.getRetainedSelf()
        if aws_credentials_provider_get_credentials(credentialProvider.rawValue, onGetCredentials, retainedSelf) != AWS_OP_SUCCESS {
            core.release()
            continuation.resume(throwing: CommonRunTimeError.crtError(CRTError.makeFromLastError()))
        }
    }

    private func release() {
        Unmanaged.passUnretained(self).release()
    }
}

/// A container class to wrap a protocol so that we use it with Unmanaged
class GetCredentialsContainer {
    let getCredentials: GetCredentials
    init(_ getCredentials: GetCredentials) {
        self.getCredentials = getCredentials
    }

    func getUnretainedSelf() -> UnsafeMutableRawPointer {
        return Unmanaged<GetCredentialsContainer>.passUnretained(self).toOpaque()
    }
}

private func onGetCredentials(credentials: OpaquePointer?,
                              errorCode: Int32,
                              userData: UnsafeMutableRawPointer!) {

    let credentialsProviderCore = Unmanaged<GetCredentialsCore>.fromOpaque(userData).takeRetainedValue()

    if errorCode != AWS_OP_SUCCESS {
        credentialsProviderCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
        return
    }

    //Success
    let crtCredentials = CRTCredentials(rawValue: credentials!)
    credentialsProviderCore.continuation.resume(returning: crtCredentials)
}
