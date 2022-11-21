//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth
import Foundation

public class HttpRequestSigner {

    /// What signing algorithm to use.
    public var algorithm: SigningAlgorithmType

    /// What sort of signature should be computed?
    public var signatureType: SignatureType

    /// name of service to sign a request for
    public var service: String

    /// Region-related configuration
    ///   (1) If Sigv4, the region to sign against
    ///   (2) If Sigv4a, the value of the X-amzn-region-set header (added in signing)
    public var region: String

    /// Raw date to use during the signing process.
    public var date: Date

    /// AWS Credentials to sign with. If Sigv4a is the algorithm and the credentials supplied are not ecc-based,
    /// a temporary ecc-based credentials object will be built and used instead.
    /// Overrides the credentialsProvider setting if non-null.
    public var credentials: AwsCredentials?

    /// AWS credentials provider to fetch credentials from.  If the signing algorithm is asymmetric sigv4, then the
    /// ecc-based credentials will be derived from the fetched credentials.
    public var credentialsProvider: AwsCredentialsProvider?

    /// If non-zero and the signing transform is query param, then signing will add X-Amz-Expires to the query
    /// string, equal to the value specified here. If this value is zero or if header signing is being used then
    /// this parameter has no effect.
    public var expiration: TimeInterval?

    /// Controls what body "hash" header, if any, should be added to the canonical request and the signed request:
    ///   none - no header should be added
    ///   contentSha256 - the body "hash" should be added in the X-Amz-Content-Sha256 header
    public var signedBodyHeader: SignedBodyHeaderType

    /// Optional string to use as the canonical request's body value.
    /// If string is empty, a value will be calculated from the payload during signing.
    /// Typically, this is the SHA-256 of the (request/chunk/event) payload, written as lowercase hex.
    /// If this has been precalculated, it can be set here. Special values used by certain services can also be set
    public var signedBodyValue: SignedBodyValue

    ///  Optional function to control which headers are a part of the canonical request.
    public var shouldSignHeader: ((String) -> Bool)?

    /// We assume the uri will be encoded once in preparation for transmission. Certain services
    /// do not decode before checking signature, requiring us to actually double-encode the uri in the canonical
    /// request in order to pass a signature check.
    public var useDoubleURIEncode: Bool

    /// Controls whether or not the uri paths should be normalized when building the canonical request
    public var shouldNormalizeURIPath: Bool

    /// Should the "X-Amz-Security-Token" query param be omitted?
    /// Normally, this parameter is added during signing if the credentials have a session token.
    /// The only known case where this should be true is when signing a websocket handshake to IoT Core.
    public var omitSessionToken: Bool

    let allocator: Allocator

    public init(algorithm: SigningAlgorithmType,
                signatureType: SignatureType,
                service: String,
                region: String,
                date: Date = Date(),
                credentials: AwsCredentials? = nil,
                credentialsProvider: AwsCredentialsProvider? = nil,
                expiration: TimeInterval? = nil,
                signedBodyHeader: SignedBodyHeaderType = .none,
                signedBodyValue: SignedBodyValue = SignedBodyValue.empty,
                shouldSignHeader: ((String) -> Bool)? = nil,
                useDoubleURIEncode: Bool = true,
                shouldNormalizeURIPath: Bool = true,
                omitSessionToken: Bool = false,
                allocator: Allocator = defaultAllocator) {

        self.algorithm = algorithm
        self.signatureType = signatureType
        self.service = service
        self.region = region
        self.date = date
        self.credentials = credentials
        self.credentialsProvider = credentialsProvider
        self.expiration = expiration
        self.signedBodyHeader = signedBodyHeader
        self.signedBodyValue = signedBodyValue
        self.shouldSignHeader = shouldSignHeader
        self.useDoubleURIEncode = useDoubleURIEncode
        self.shouldNormalizeURIPath = shouldNormalizeURIPath
        self.omitSessionToken = omitSessionToken
        self.allocator = allocator
    }

    func getSigningConfig() -> aws_signing_config_aws {
        var config = aws_signing_config_aws()
        config.algorithm = algorithm.rawValue
        config.signature_type = signatureType.rawValue
        config.date = date.toAWSDate()
        config.credentials = credentials?.rawValue
        config.credentials_provider = credentialsProvider?.rawValue
        config.expiration_in_seconds = UInt64(expiration ?? 0)
        config.signed_body_header = signedBodyHeader.rawValue

        config.flags = aws_signing_config_aws.__Unnamed_struct_flags()
        config.flags.use_double_uri_encode = useDoubleURIEncode.uintValue
        config.flags.should_normalize_uri_path = shouldNormalizeURIPath.uintValue
        config.flags.omit_session_token = omitSessionToken.uintValue
        config.config_type = AWS_SIGNING_CONFIG_AWS

        return config
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
    public func signRequest(request: HttpRequest) async throws -> HttpRequest {

        let signable = aws_signable_new_http_request(allocator.rawValue, request.rawValue)
        defer {
            aws_signable_destroy(signable)
        }
        var config = getSigningConfig()

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HttpRequest, Error>) in
            withByteCursorFromStrings(region,
                    service,
                    signedBodyValue.rawValue) { regionCursor,
                                                serviceCursor,
                                                signedBodyValueCursor in
                config.region = regionCursor
                config.service = serviceCursor
                config.signed_body_value = signedBodyValueCursor
                let signRequestCore = SignRequestCore(request: request,
                        continuation: continuation,
                        shouldSignHeader: shouldSignHeader,
                        allocator: self.allocator)

                if shouldSignHeader != nil {
                    config.should_sign_header_ud = signRequestCore.passUnretained()
                    config.should_sign_header = onShouldSignHeader
                }

                withUnsafePointer(to: config) { configPointer in
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
