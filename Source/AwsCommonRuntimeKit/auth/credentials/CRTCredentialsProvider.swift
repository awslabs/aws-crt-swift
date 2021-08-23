//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth

private func getCredentialsFn(_ credentialsProviderPtr: UnsafeMutablePointer<aws_credentials_provider>?,
                              _ callbackFn: (@convention(c)(OpaquePointer?, Int32, UnsafeMutableRawPointer?) -> Void)?,
                              userData: UnsafeMutableRawPointer?) -> Int32 {
    
    guard let credentialsProvider = userData?.assumingMemoryBound(to: CRTCredentialsProvider.self) else {
        return 1
    }
    
    var credentialCallbackData = CRTCredentialsProviderCallbackData(allocator: credentialsProvider.pointee.allocator)
    let callbackPointer = UnsafeMutablePointer<CRTCredentialsProviderCallbackData>.allocate(capacity: 1)
    credentialCallbackData.onCredentialsResolved = { (credentials, crtError) in
        if case let CRTError.crtError(error) = crtError {
            callbackFn?(credentials?.rawValue, error.errorCode, callbackPointer)
        }
    }
    callbackPointer.initialize(to: credentialCallbackData)
    credentialsProvider.pointee.getCredentials(credentialCallbackData: credentialCallbackData)
    return 0
}

public protocol CRTCredentialsProvider {
    var allocator: Allocator {get set}
    func getCredentials(credentialCallbackData: CRTCredentialsProviderCallbackData)
    
}

struct WrappedCRTCredentialsProvider {
    var rawValue: UnsafeMutablePointer<aws_credentials_provider>
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
        let shutDownOptions = WrappedCRTCredentialsProvider.setUpShutDownOptions(shutDownOptions: shutDownOptions)
        let atomicVar = Atomic<Int>(1)
        self.allocator = allocator
        let credProviderPtr: UnsafeMutablePointer<CRTCredentialsProvider> = fromPointer(ptr: impl)
        let vTablePtr: UnsafeMutablePointer<aws_credentials_provider_vtable> = fromPointer(ptr: vtable)
        self.vTablePtr = vTablePtr
        self.implementationPtr = credProviderPtr
        let credProvider = aws_credentials_provider(vtable: vTablePtr,
                                                    allocator: allocator.rawValue,
                                                    shutdown_options: shutDownOptions,
                                                    impl: credProviderPtr,
                                                    ref_count: atomicVar.rawValue)
        self.rawValue = fromPointer(ptr: credProvider)
        
    }
    
    static func setUpShutDownOptions(shutDownOptions: CRTCredentialsProviderShutdownOptions?)
    -> aws_credentials_provider_shutdown_options {
        
        let pointer: UnsafeMutablePointer<CRTCredentialsProviderShutdownOptions>? = fromOptionalPointer(ptr: shutDownOptions)
        let shutDownOptionsC = aws_credentials_provider_shutdown_options(shutdown_callback: { userData in
            guard let userData = userData else {
                return
            }
            let pointer = userData.assumingMemoryBound(to: CRTCredentialsProviderShutdownOptions.self)
            defer {pointer.deinitializeAndDeallocate()}
            pointer.pointee.shutDownCallback()
            
        }, shutdown_user_data: pointer)
        
        return shutDownOptionsC
    }
}
