//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth

public class SigV4HttpRequestSigner {
    public var allocator: Allocator

    public init(allocator: Allocator = defaultAllocator) {
        self.allocator = allocator
    }

    /// Signs an HttpRequest via the SigV4 algorithm.
    /// Do not add the following headers to requests before signing:
    ///   - x-amz-content-sha256,
    ///   - X-Amz-Date,
    ///   - Authorization
    ///
    /// Do not add the following query params to requests before signing:
    ///   - X-Amz-Signature,
    ///   - X-Amz-Date,
    ///   - X-Amz-Credential,
    ///   - X-Amz-Algorithm,
    ///   - X-Amz-SignedHeaders
    ///
    /// The signing result will tell exactly what header and/or query params to add to the request to
    /// become a fully-signed AWS http request.
    ///
    /// - `Parameters`:
    ///    - `request`:  The `HttpRequest`to be signed.
    ///    - `config`: The `SigningConfig` to use when signing.
    /// - `Throws`: An error of type `AwsCommonRuntimeError` which will pull last error found in the CRT
    /// - `Returns`: Returns a future with a signed http request `Future<HttpRequest>`
    public func signRequest(request: HttpRequest, config: SigningConfig) throws -> Future<HttpRequest> {
        let future = Future<HttpRequest>()
        if config.configType != .aws {
            throw AWSCommonRuntimeError()
        }

        if config.rawValue.credentials_provider == nil && config.rawValue.credentials == nil {
            throw AWSCommonRuntimeError()
        }
        let signable = aws_signable_new_http_request(allocator.rawValue, request.rawValue)
        
        let onSigningComplete: OnSigningComplete = { [self]signingResult, httpRequest, crtError in
            if let signingResult = signingResult {
                let signedRequest = self.applySigningResult(signingResult: signingResult, request: httpRequest)
                switch signedRequest {
                case .failure(let error):
                    future.fail(error)
                case .success(let request):
                    future.fulfill(request)
                }
            }
            future.fail(crtError)
        }

        let callbackData = SigningCallbackData(allocator: allocator.rawValue,
                                               request: request,
                                               signable: signable,
                                               onSigningComplete: onSigningComplete)

        let configPointer = UnsafeMutablePointer<aws_signing_config_aws>.allocate(capacity: 1)
        configPointer.initialize(to: config.rawValue)
        let base = configPointer.withMemoryRebound(to: aws_signing_config_base.self,
                                                   capacity: 1) { (configPointer)
            -> UnsafeMutablePointer<aws_signing_config_base> in
            return configPointer
        }
        let configPtr = UnsafePointer(base)

        let callbackPointer = UnsafeMutablePointer<SigningCallbackData>.allocate(capacity: 1)
        callbackPointer.initialize(to: callbackData)

        defer {
            base.deinitializeAndDeallocate()
        }

        if aws_sign_request_aws(allocator.rawValue,
                                    signable,
                                    configPtr, { (signingResult, errorCode, userData) -> Void in
                                        guard let userData = userData else {
                                            return
                                        }
                                        let callback = userData.assumingMemoryBound(to: SigningCallbackData.self)
                                        defer {
                                            aws_signable_destroy(callback.pointee.signable)
                                            callback.deinitializeAndDeallocate()
                                        }
                                        let error = AWSError(errorCode: errorCode)
                                        callback.pointee.onSigningComplete(SigningResult(rawValue: signingResult),
                                                                           callback.pointee.request,
                                                                           CRTError.crtError(error))
        },
                                    callbackPointer) != AWS_OP_SUCCESS {
            throw AWSCommonRuntimeError()
        }
        
        return future
    }

    public func applySigningResult(signingResult: SigningResult, request: HttpRequest) -> Result<HttpRequest, CRTError> {
        if aws_apply_signing_result_to_http_request(request.rawValue,
                                                    allocator.rawValue,
                                                    signingResult.rawValue) == AWS_OP_SUCCESS {
            return .success(request)
        } else {
            let error = AWSCommonRuntimeError()
            let awsError = AWSError(errorCode: error.code)
            return .failure(CRTError.crtError(awsError))
        }
    }
}
