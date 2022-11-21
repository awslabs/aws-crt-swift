//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth
import Foundation

//TODO: update file name
public class HttpRequestSigner {

    static func getCSigningConfig(config: SigningConfig) -> aws_signing_config_aws {
        var cConfig = aws_signing_config_aws()
        cConfig.algorithm = config.algorithm.rawValue
        cConfig.signature_type = config.signatureType.rawValue
        cConfig.date = config.date.toAWSDate()
        cConfig.credentials = config.credentials?.rawValue
        cConfig.credentials_provider = config.credentialsProvider?.rawValue
        cConfig.expiration_in_seconds = UInt64(config.expiration ?? 0)
        cConfig.signed_body_header = config.signedBodyHeader.rawValue

        cConfig.flags = aws_signing_config_aws.__Unnamed_struct_flags()
        cConfig.flags.use_double_uri_encode = config.useDoubleURIEncode.uintValue
        cConfig.flags.should_normalize_uri_path = config.shouldNormalizeURIPath.uintValue
        cConfig.flags.omit_session_token = config.omitSessionToken.uintValue
        cConfig.config_type = AWS_SIGNING_CONFIG_AWS

        return cConfig
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
    public static func signRequest(request: HttpRequest, config: SigningConfig, allocator: Allocator = defaultAllocator) async throws -> HttpRequest {

        let signable = aws_signable_new_http_request(allocator.rawValue, request.rawValue)
        defer {
            aws_signable_destroy(signable)
        }
        var cConfig = getCSigningConfig(config: config)

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HttpRequest, Error>) in
            withByteCursorFromStrings(config.region,
                    config.service,
                    config.signedBodyValue.rawValue) { regionCursor,
                                                serviceCursor,
                                                signedBodyValueCursor in
                cConfig.region = regionCursor
                cConfig.service = serviceCursor
                cConfig.signed_body_value = signedBodyValueCursor
                let signRequestCore = SignRequestCore(request: request,
                        continuation: continuation,
                        shouldSignHeader: config.shouldSignHeader,
                        allocator: allocator)

                if config.shouldSignHeader != nil {
                    cConfig.should_sign_header_ud = signRequestCore.passUnretained()
                    cConfig.should_sign_header = onShouldSignHeader
                }

                withUnsafePointer(to: cConfig) { configPointer in
                    configPointer.withMemoryRebound(to: aws_signing_config_base.self, capacity: 1) { configBasePointer in
                        if aws_sign_request_aws(allocator.rawValue, signable, configBasePointer, onSigningComplete, signRequestCore.passRetained())
                                   != AWS_OP_SUCCESS {
                            signRequestCore.release()
                            continuation.resume(throwing: CommonRunTimeError.crtError(.makeFromLastError()))
                        }
                    }
                }
            }
        }
    }
}

class SignRequestCore {
    let allocator: Allocator
    let request: HttpRequest
    var continuation: CheckedContinuation<HttpRequest, Error>
    let shouldSignHeader: ((String) -> Bool)?
    init(request: HttpRequest,
         continuation: CheckedContinuation<HttpRequest, Error>,
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

private func onShouldSignHeader(nameCursor: UnsafePointer<aws_byte_cursor>!,
                                userData: UnsafeMutableRawPointer!) -> Bool {
    let signRequestCore = Unmanaged<SignRequestCore>.fromOpaque(userData).takeUnretainedValue()
    let name = nameCursor.pointee.toString()!
    return signRequestCore.shouldSignHeader!(name)
}

private func onSigningComplete(signingResult: UnsafeMutablePointer<aws_signing_result>?,
                               errorCode: Int32,
                               userData: UnsafeMutableRawPointer!) {
    let signRequestCore = Unmanaged<SignRequestCore>.fromOpaque(userData).takeRetainedValue()
    if errorCode != AWS_OP_SUCCESS {
        signRequestCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
        return
    }

    //Success
    let signedRequest = aws_apply_signing_result_to_http_request(signRequestCore.request.rawValue,
            signRequestCore.allocator.rawValue,
            signingResult!)
    if signedRequest == AWS_OP_SUCCESS {
        signRequestCore.continuation.resume(returning: signRequestCore.request)
    } else {
        signRequestCore.continuation.resume(throwing: CommonRunTimeError.crtError(.makeFromLastError()))
    }
}
