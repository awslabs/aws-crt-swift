//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth

class SigV4HttpRequestSigner {
    public var allocator: Allocator

    public init(allocator: Allocator = defaultAllocator) {
        self.allocator = allocator
    }
    
    public func signRequest(request: HttpRequest, config: SigningConfig, callback: @escaping OnRequestSigningComplete) throws {
        if config.configType != .aws {
            throw AwsCommonRuntimeError()
        }
        
        guard let _ = config.rawValue.credentials_provider,
            let _ = config.rawValue.credentials else {
            throw AwsCommonRuntimeError()
        }
        
        let callbackData = SigningCallbackData(request: request, onRequestSigningComplete: callback)
        
        let signable = aws_signable_new_http_request(allocator.rawValue, request.rawValue)
        let configPointer = UnsafeMutablePointer<aws_signing_config_aws>.allocate(capacity: 1)
        configPointer.initialize(to: config.rawValue)
        let base = unsafeBitCast(configPointer, to: UnsafeMutablePointer<aws_signing_config_base>.self)
        let configPtr = UnsafePointer(base)
        
        let callbackPointer = UnsafeMutablePointer<SigningCallbackData>.allocate(capacity: 1)
        callbackPointer.initialize(to: callbackData)
        
        defer{
            //signable?.deallocate()
            configPointer.deinitializeAndDeallocate()
            destroySignable(signable: signable!)
        }
        
        if aws_sign_request_aws(allocator.rawValue,
                                    signable,
                                    configPtr,
                                    { (signingResult, errorCode, userData) -> Void in
                                        guard let userData = userData else {
                                            return
                                        }
                                        let callback = userData.assumingMemoryBound(to: SigningCallbackData.self)
                                        if errorCode == AWS_OP_SUCCESS {
                                            aws_apply_signing_result_to_http_request(callback.pointee.request.rawValue,
                                                                                     callback.pointee.allocator.rawValue,
                                                                                     signingResult)
                                        }
                                        defer {
                                            callback.deinitializeAndDeallocate()
                                            signingResult?.deinitializeAndDeallocate()
                                        }
                                        callback.pointee.onRequestSigningComplete(callback.pointee.request, Int(errorCode))
        },
                                    callbackPointer) != AWS_OP_SUCCESS {
            throw AwsCommonRuntimeError()
        }
    }
    
    func destroySignable(signable: UnsafeMutablePointer<aws_signable>) {
         aws_signable_destroy(signable)
    }
    
    deinit {
       
    }
}
