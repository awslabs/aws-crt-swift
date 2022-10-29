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
    /// - `Returns`: Returns a signed http request `HttpRequest`
    public func signRequest(request: HttpRequest, config: SigningConfig) async throws -> HttpRequest {
        typealias SignedContinuation = CheckedContinuation<HttpRequest, Error>

        //TODO: Fix. This is weird. We should not throw make from last error here.
        if config.configType != .aws || (config.credentialsProvider == nil && config.credentials == nil) {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }

        return try await withCheckedThrowingContinuation { (continuation: SignedContinuation) in
            signRequestToCRT(request: request, config: config, continuation: continuation)
        }
    }

    private func signRequestToCRT(request: HttpRequest, config: SigningConfig, continuation: SignedContinuation) {
        let signable = aws_signable_new_http_request(allocator.rawValue, request.rawValue)

        let callbackData = SigningCallbackData(allocator: allocator.rawValue,
                                               request: request,
                                               signable: signable,
                                               continuation: continuation)
        //TODO: fix callback
        config.withCPointer { configPointer in
            configPointer.withMemoryRebound(to: aws_signing_config_base.self, capacity: 1) { configBasePointer in
                let callbackPointer: UnsafeMutablePointer<SigningCallbackData> = fromPointer(ptr: callbackData)
                aws_sign_request_aws(allocator.rawValue,
                        signable,
                        configBasePointer, { (signingResult, errorCode, userData) -> Void in

                    let callback = userData!.assumingMemoryBound(to: SigningCallbackData.self)
                    defer {
                        aws_signable_destroy(callback.pointee.signable)
                        callback.deinitializeAndDeallocate()
                    }

                    if let continuation = callback.pointee.continuation {
                        if errorCode == 0,
                           let signingResult = signingResult {

                            let signedRequest = aws_apply_signing_result_to_http_request(callback.pointee.request.rawValue,
                                    callback.pointee.allocator.rawValue,
                                    signingResult)
                            if signedRequest == 0 {
                                continuation.resume(returning: callback.pointee.request)
                            } else {
                                continuation.resume(throwing: CommonRunTimeError
                                        .crtError(CRTError(code: signedRequest)))
                            }
                        } else {
                            continuation.resume(throwing: CommonRunTimeError
                                    .crtError(CRTError(code: errorCode)))
                        }
                    }

                }, callbackPointer)
            }
        }
    }
}
