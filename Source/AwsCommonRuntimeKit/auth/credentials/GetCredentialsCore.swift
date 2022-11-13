//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth

typealias CredentialsContinuation = CheckedContinuation<CRTCredentials, Error>

/// Core classes have manual memory management.
/// You have to balance the retain & release calls in all cases to avoid leaking memory.
class GetCredentialsCore {
    public var continuation: CredentialsContinuation

    public init(continuation: CredentialsContinuation) {
        self.continuation = continuation
    }

    private func getRetainedSelf() -> UnsafeMutableRawPointer {
        return Unmanaged<GetCredentialsCore>.passRetained(self).toOpaque()
    }

    func getRetainedCredentials(credentialProvider: CredentialsProvider) {
        let retainedSelf = getRetainedSelf()
        if aws_credentials_provider_get_credentials(credentialProvider.rawValue, onGetCredentials, retainedSelf) != AWS_OP_SUCCESS {
            release()
            continuation.resume(throwing: CommonRunTimeError.crtError(CRTError.makeFromLastError()))
        }
    }

    private func release() {
        Unmanaged.passUnretained(self).release()
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
