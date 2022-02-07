//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth

private func getCredentialsFn(_ credentialsProviderPtr: UnsafeMutablePointer<aws_credentials_provider>?,
                              _ callbackFn: (@convention(c)(OpaquePointer?, Int32, UnsafeMutableRawPointer?) -> Void)?,
                              userData: UnsafeMutableRawPointer?) -> Int32 {

    guard let credentialsProvider = userData?.assumingMemoryBound(to: CRTCredentialsProvider.self) else {
        return 1
    }

    let credentialCallbackData = CRTCredentialsProviderCallbackData(allocator: credentialsProvider.pointee.allocator)
    let callbackPointer = UnsafeMutablePointer<CRTCredentialsProviderCallbackData>.allocate(capacity: 1)
    callbackPointer.initialize(to: credentialCallbackData)
    async {
        let result = await credentialsProvider.pointee.getCredentials()
        switch result {
        case .success(let credentials):
            callbackFn?(credentials.rawValue, 0, callbackPointer)
        case .failure(let error):
            if case let CRTError.crtError(crtError) = error {
                callbackFn?(nil, crtError.errorCode, callbackPointer)
            }
        }
    }
    
   return 0
}

public protocol CRTCredentialsProvider {
    var allocator: Allocator {get set}
    func getCredentials() async -> Result<CRTCredentials, CRTError>

}

class WrappedCRTCredentialsProvider {
    var rawValue: aws_credentials_provider
    let allocator: Allocator
    private let implementationPtr: UnsafeMutablePointer<CRTCredentialsProvider>
    private let vTablePtr: UnsafeMutablePointer<aws_credentials_provider_vtable>

    init(impl: CRTCredentialsProvider,
         allocator: Allocator,
         shutDownOptions: CRTCredentialsProviderShutdownOptions? = nil) {
        let vtable = aws_credentials_provider_vtable(get_credentials: getCredentialsFn,
                                                     destroy: { (credentialsProviderPtr) in
            guard let credentialsProviderPtr = credentialsProviderPtr else {
                return
            }

            aws_credentials_provider_release(credentialsProviderPtr)

        })
        let shutDownOptions = Self.setUpShutDownOptions(shutDownOptions: shutDownOptions)
        let intPointer = UnsafeMutablePointer<Int>.allocate(capacity: 1)
        intPointer.pointee = 1
        let atomicVar = aws_atomic_var(value: UnsafeMutableRawPointer(intPointer))
        self.allocator = allocator
        let credProviderPtr = UnsafeMutablePointer<CRTCredentialsProvider>.allocate(capacity: 1)
        credProviderPtr.initialize(to: impl)
        let vTablePtr = UnsafeMutablePointer<aws_credentials_provider_vtable>.allocate(capacity: 1)
        vTablePtr.initialize(to: vtable)
        self.vTablePtr = vTablePtr
        self.implementationPtr = credProviderPtr
        self.rawValue = aws_credentials_provider(vtable: vTablePtr,
                                                 allocator: allocator.rawValue,
                                                 shutdown_options: shutDownOptions,
                                                 impl: credProviderPtr,
                                                 ref_count: atomicVar)

    }

    static func setUpShutDownOptions(shutDownOptions: CRTCredentialsProviderShutdownOptions?)
    -> aws_credentials_provider_shutdown_options {
        let shutDownOptionsC: aws_credentials_provider_shutdown_options?
        if let shutDownOptions = shutDownOptions {

            let pointer = UnsafeMutablePointer<CRTCredentialsProviderShutdownOptions>.allocate(capacity: 1)
            pointer.initialize(to: shutDownOptions)
            shutDownOptionsC = aws_credentials_provider_shutdown_options(shutdown_callback: { userData in
                guard let userData = userData else {
                    return
                }
                let pointer = userData.assumingMemoryBound(to: CRTCredentialsProviderShutdownOptions.self)
                defer {pointer.deinitializeAndDeallocate()}
                pointer.pointee.shutDownCallback()

            }, shutdown_user_data: pointer)
        } else {
            shutDownOptionsC = aws_credentials_provider_shutdown_options()
        }
        return shutDownOptionsC!
    }

    deinit {
        implementationPtr.deinitializeAndDeallocate()
        vTablePtr.deinitializeAndDeallocate()
    }
}
