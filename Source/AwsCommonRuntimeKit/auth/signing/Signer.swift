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
        config: SigningConfig) async throws -> HTTPRequestBase {

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
                                                  shouldSignHeader: config.shouldSignHeader)
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
                        onRequestSigningComplete,
                        signRequestCore.passRetained())
                        != AWS_OP_SUCCESS {

                        signRequestCore.release()
                        continuation.resume(throwing: CommonRunTimeError.crtError(.makeFromLastError()))
                    }
                }
            }
        }
    }

    /// Signs a body chunk according to the supplied signing configuration
    /// - Parameters:
    ///   - chunk: Chunk to sign
    ///   - previousSignature: The signature of the previous component of the request: either the request itself for the first chunk,
    ///                        or the previous chunk otherwise.
    ///    - config: The `SigningConfig` to use when signing.
    /// - Returns: Signature of the chunk
    /// - Throws: CommonRunTimeError.crtError
    public static func signChunk(chunk: Data,
                                 previousSignature: String,
                                 config: SigningConfig) async throws -> String {
        let iStreamCore = IStreamCore(iStreamable: ByteBuffer(data: chunk))
        guard let signable = previousSignature.withByteCursorPointer({ previousSignatureCursor in
            aws_signable_new_chunk(allocator.rawValue, iStreamCore.rawValue, previousSignatureCursor.pointee)
        }) else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        defer {
            aws_signable_destroy(signable)
        }

        return try await sign(config: config, signable: signable)
    }

    /// Signs an event stream encoded event according to the supplied signing configuration.
    /// You can use `EventStreamMessage.getEncoded` to encode the event.
    /// - Parameters:
    ///   - event: Encoded event to sign
    ///   - previousSignature: The signature of the previous component of the request: either the request itself for the first event,
    ///                        or the previous event otherwise.
    ///   - config: The `SigningConfig` to use when signing. The `SignatureType` must be `requestEvent`.
    /// - Returns: Signature of the event. You will need to add the signature as well as date header to the request.
    /// - Throws: CommonRunTimeError.crtError
    public static func signEvent(event: Data,
                                 previousSignature: String,
                                 config: SigningConfig) async throws -> String {
        guard config.signatureType == SignatureType.requestEvent else {
            throw CommonRunTimeError.crtError(.init(code: AWS_AUTH_SIGNING_MISMATCHED_CONFIGURATION.rawValue))
        }
        return try await signChunk(
            chunk: event,
            previousSignature: previousSignature,
            config: config)
    }

    /// Signs trailing headers according to the supplied signing configuration
    /// - Parameters:
    ///   - headers: list of headers to be sent in the trailer.
    ///   - previousSignature: The signature of the previous component of the request: either the request itself for the first chunk,
    ///                        or the previous chunk otherwise.
    ///   - config: The `SigningConfig` to use when signing.
    /// - Returns: Signing Result
    /// - Throws: CommonRunTimeError.crtError
    public static func signTrailerHeaders(headers: [HTTPHeader],
                                          previousSignature: String,
                                          config: SigningConfig) async throws -> String {

        guard let signable = previousSignature.withByteCursorPointer({ previousSignatureCursor in
            headers.withCHeaders { cHeaders in
                aws_signable_new_trailing_headers(allocator.rawValue, cHeaders, previousSignatureCursor.pointee)
            }
        }) else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        defer {
            aws_signable_destroy(signable)
        }
        return try await sign(config: config, signable: signable)
    }

    private static func sign(config: SigningConfig,
                             signable: UnsafePointer<aws_signable>) async throws -> String {

        try await withCheckedThrowingContinuation { continuation in
            config.withCPointer { configPointer in
                configPointer.withMemoryRebound(to: aws_signing_config_base.self,
                                                capacity: 1) { configBasePointer in
                    let continuationCore = ContinuationCore(continuation: continuation)
                    if aws_sign_request_aws(allocator.rawValue,
                                            signable,
                                            configBasePointer,
                                            onSigningComplete,
                                            continuationCore.passRetained())
                        != AWS_OP_SUCCESS {
                        continuationCore.release()
                        continuation.resume(throwing: CommonRunTimeError.crtError(.makeFromLastError()))
                    }
                }
            }
        }
    }
}

class SignRequestCore {
    let request: HTTPRequestBase
    var continuation: CheckedContinuation<HTTPRequestBase, Error>
    let shouldSignHeader: ((String) -> Bool)?
    init(request: HTTPRequestBase,
         continuation: CheckedContinuation<HTTPRequestBase, Error>,
         shouldSignHeader: ((String) -> Bool)? = nil) {
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

private func onRequestSigningComplete(signingResult: UnsafeMutablePointer<aws_signing_result>?,
                                      errorCode: Int32,
                                      userData: UnsafeMutableRawPointer!) {
    let signRequestCore = Unmanaged<SignRequestCore>.fromOpaque(userData).takeRetainedValue()
    if errorCode != AWS_OP_SUCCESS {
        signRequestCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
        return
    }

    // Success
    let signedRequest = aws_apply_signing_result_to_http_request(signRequestCore.request.rawValue,
                                                                 allocator.rawValue,
                                                                 signingResult!)
    if signedRequest == AWS_OP_SUCCESS {
        signRequestCore.continuation.resume(returning: signRequestCore.request)
    } else {
        signRequestCore.continuation.resume(throwing: CommonRunTimeError.crtError(.makeFromLastError()))
    }
}

private func onSigningComplete(signingResult: UnsafeMutablePointer<aws_signing_result>?,
                               errorCode: Int32,
                               userData: UnsafeMutableRawPointer!) {
    let chunkSignerCore = Unmanaged<ContinuationCore<String>>.fromOpaque(userData).takeRetainedValue()
    guard errorCode == AWS_OP_SUCCESS else {
        chunkSignerCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
        return
    }

    // Success
    var awsStringPointer: UnsafeMutablePointer<aws_string>!
    guard aws_signing_result_get_property(
            signingResult!,
            g_aws_signature_property_name,
            &awsStringPointer) == AWS_OP_SUCCESS else {
        chunkSignerCore.continuation.resume(throwing: CommonRunTimeError.crtError(.makeFromLastError()))
        return
    }
    chunkSignerCore.continuation.resume(returning: String(awsString: awsStringPointer)!)
}
