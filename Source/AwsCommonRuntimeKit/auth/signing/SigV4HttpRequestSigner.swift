//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth

class SigV4HttpRequestSigner {
    public var allocator: Allocator

    public init(allocator: Allocator = defaultAllocator) {
        self.allocator = allocator
    }
    
    public func signRequest(request: HttpRequest, config: SigningConfig, callback: @escaping OnRequestSigningComplete) throws -> Bool {
        if config.configType != .aws {
            throw AwsCommonRuntimeError()
        }
        
        guard let credentialsProvider = config.rawValue.credentials_provider, let credentials = config.rawValue.credentials else {
            throw AwsCommonRuntimeError()
        }
        
        let callbackData = SigningCallbackData(request: request, onRequestSigningComplete: callback)
        
        
        let signable = UnsafePointer(aws_signable_new_http_request(allocator.rawValue, request.rawValue))
        let base = unsafeBitCast(config, to: aws_signing_config_base.self)
        let configMutablePointer: UnsafeMutablePointer<aws_signing_config_base>?
        configMutablePointer = UnsafeMutablePointer<aws_signing_config_base>.allocate(capacity: 1)
        configMutablePointer?.initialize(to: base)
        let configPointer = UnsafePointer(configMutablePointer)
        
        
        let callbackPointer = UnsafeMutablePointer<SigningCallbackData>.allocate(capacity: 1)
        callbackPointer.initialize(to: callbackData)
        
        defer{
            signable?.deallocate()
            configMutablePointer?.deinitializeAndDeallocate()
            configPointer?.deallocate()
            callbackPointer.deinitializeAndDeallocate()
        }
        
        return aws_sign_request_aws(allocator.rawValue,
                                    signable,
                                    configPointer,
                                    { (signingResult, errorCode, userData) -> Void in
                                        guard let userData = userData else {
                                            return
                                        }
                                        let callback = userData.bindMemory(to: SigningCallbackData.self, capacity: 1)
                                        if errorCode == AWS_OP_SUCCESS {
                                            aws_apply_signing_result_to_http_request(callback.pointee.request.rawValue,
                                                                                     callback.pointee.allocator.rawValue,
                                                                                     signingResult)
                                        }
                                        callback.pointee.onRequestSigningComplete(callback.pointee.request, Int(errorCode))
        },
                                    callbackPointer) == AWS_OP_SUCCESS
    }
}
