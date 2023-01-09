//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth
import Foundation

public class Signer {

    /// Signs an HttpRequest that was passed in via the appropriate algorithm.
    /// This function returns a reference to the same request object that was passed in.
    /// So request in parameter will also be signed when the signing completes.
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
    public static func signRequest(
        request: HTTPRequestBase,
        config: SigningConfig,
        allocator: Allocator = defaultAllocator) async throws -> HTTPRequestBase {

        guard let signable = aws_signable_new_http_request(allocator.rawValue, request.rawValue) else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        defer {
            aws_signable_destroy(signable)
        }

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<
                                                                HTTPRequestBase,
                                                                Error>) in
            let signRequestCore = SignRequestCore(request: request,
                                                  continuation: continuation,
                                                  shouldSignHeader: config.shouldSignHeader,
                                                  allocator: allocator)
            var shouldSignHeaderUserData: UnsafeMutableRawPointer?
            if config.shouldSignHeader != nil {
                shouldSignHeaderUserData = signRequestCore.passUnretained()
            }
            config.withCPointer(userData: shouldSignHeaderUserData) { configPointer in
                configPointer.withMemoryRebound(
                    to: aws_signing_config_base.self,
                    capacity: 1) { configBasePointer in

                    if aws_sign_request_aws(
                        allocator.rawValue,
                        signable,
                        configBasePointer,
                        onSigningComplete,
                        signRequestCore.passRetained())
                        != AWS_OP_SUCCESS {

                        signRequestCore.release()
                        continuation.resume(throwing: CommonRunTimeError.crtError(.makeFromLastError()))
                    }
                }
            }
        }
    }
}

class SignRequestCore {
    let allocator: Allocator
    let request: HTTPRequestBase
    var continuation: CheckedContinuation<HTTPRequestBase, Error>
    let shouldSignHeader: ((String) -> Bool)?
    init(request: HTTPRequestBase,
         continuation: CheckedContinuation<HTTPRequestBase, Error>,
         shouldSignHeader: ((String) -> Bool)? = nil,
         allocator: Allocator) {
        self.allocator = allocator
        self.request = request
        self.continuation = continuation
        self.shouldSignHeader = shouldSignHeader
    }

    func passRetained() -> UnsafeMutableRawPointer {
        return Unmanaged.passRetained(self).toOpaque()
    }

    func passUnretained() -> UnsafeMutableRawPointer {
        return Unmanaged.passUnretained(self).toOpaque()
    }

    func release() {
        Unmanaged.passUnretained(self).release()
    }
}

private func onSigningComplete(signingResult: UnsafeMutablePointer<aws_signing_result>?,
                               errorCode: Int32,
                               userData: UnsafeMutableRawPointer!) {
    let signRequestCore = Unmanaged<SignRequestCore>.fromOpaque(userData).takeRetainedValue()
    if errorCode != AWS_OP_SUCCESS {
        signRequestCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
        return
    }

    // Success
    let signedRequest = aws_apply_signing_result_to_http_request(signRequestCore.request.rawValue,
                                                                 signRequestCore.allocator.rawValue,
                                                                 signingResult!)
    if signedRequest == AWS_OP_SUCCESS {
        signRequestCore.continuation.resume(returning: signRequestCore.request)
    } else {
        signRequestCore.continuation.resume(throwing: CommonRunTimeError.crtError(.makeFromLastError()))
    }
}
