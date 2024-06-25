//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth
import Foundation

public struct SigningConfig: CStructWithUserData {

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
    public var credentials: Credentials?

    /// AWS credentials provider to fetch credentials from.  If the signing algorithm is asymmetric sigv4, then the
    /// ecc-based credentials will be derived from the fetched credentials.
    public var credentialsProvider: CredentialsProvider?

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

    public init(algorithm: SigningAlgorithmType,
                signatureType: SignatureType,
                service: String,
                region: String,
                date: Date = Date(),
                credentials: Credentials? = nil,
                credentialsProvider: CredentialsProvider? = nil,
                expiration: TimeInterval? = nil,
                signedBodyHeader: SignedBodyHeaderType = .none,
                signedBodyValue: SignedBodyValue = SignedBodyValue.empty,
                shouldSignHeader: ((String) -> Bool)? = nil,
                useDoubleURIEncode: Bool = true,
                shouldNormalizeURIPath: Bool = true,
                omitSessionToken: Bool = false) {

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
    }

    typealias RawType = aws_signing_config_aws
    func withCStruct<Result>(userData: UnsafeMutableRawPointer?, _ body: (aws_signing_config_aws) -> Result) -> Result {
        var cConfig = aws_signing_config_aws()
        cConfig.algorithm = algorithm.rawValue
        cConfig.signature_type = signatureType.rawValue
        cConfig.date = date.toAWSDate()
        cConfig.credentials = credentials?.rawValue
        cConfig.credentials_provider = credentialsProvider?.rawValue
        cConfig.expiration_in_seconds = UInt64(expiration ?? 0)
        cConfig.signed_body_header = signedBodyHeader.rawValue

        cConfig.flags = aws_signing_config_aws.__Unnamed_struct_flags()
        cConfig.flags.use_double_uri_encode = useDoubleURIEncode.uintValue
        cConfig.flags.should_normalize_uri_path = shouldNormalizeURIPath.uintValue
        cConfig.flags.omit_session_token = omitSessionToken.uintValue
        cConfig.config_type = AWS_SIGNING_CONFIG_AWS

        if let userData = userData {
            cConfig.should_sign_header = onShouldSignHeader
            cConfig.should_sign_header_ud = userData
        }
        return withByteCursorFromStrings(
            region,
            service,
            signedBodyValue.description) { regionCursor, serviceCursor, signedBodyValueCursor in

            cConfig.region = regionCursor
            cConfig.service = serviceCursor
            cConfig.signed_body_value = signedBodyValueCursor
            return body(cConfig)
        }
    }
}

private func onShouldSignHeader(nameCursor: UnsafePointer<aws_byte_cursor>!,
                                userData: UnsafeMutableRawPointer!) -> Bool {
    let signRequestCore = Unmanaged<SignRequestCore>.fromOpaque(userData).takeUnretainedValue()
    let name = nameCursor.pointee.toString()
    return signRequestCore.shouldSignHeader!(name)
}

public enum SignatureType {

    /// A signature for a full http request should be computed, with header updates applied to the signing result.
    case requestHeaders

    /// A signature for a full http request should be computed, with query param updates applied to the signing result.
    case requestQueryParams

    /// Compute a signature for a payload chunk. The signable's input stream should be the chunk data and the
    /// signable should contain the most recent signature value (either the original http request or the most recent
    /// chunk) in the "previous-signature" property.
    case requestChunk

    /// Compute a signature for the trailing headers.
    /// the signable should contain the most recent signature value (either the original http request or the most recent
    /// chunk) in the "previous-signature" property.
    case requestTrailingHeaders

    /// Compute a signature for an event stream event. The input should be the encoded event-stream
    /// message (headers + payload), the signable should contain the most recent signature value (either the original
    /// http request or the most recent event) in the "previous-signature" property.
    ///
    /// This option is only supported for Sigv4 for now.
    case requestEvent
}

public enum SignedBodyHeaderType {

    /// Do not add a header
    case none

    /// Add the "x-amz-content-sha256" header with the canonical request's body value
    case contentSha256
}

/// Optional string to use as the canonical request's body value.
/// Typically, this is the SHA-256 of the (request/chunk/event) payload, written as lowercase hex.
/// If this has been precalculated, it can be set here. Special values used by certain services can also be set.
public enum SignedBodyValue: CustomStringConvertible, Equatable {
    /// if empty, a public value  will be calculated from the payload during signing
    case empty
    /// For empty sha256
    case emptySha256
    /// Use this to provide a precalculated sha256 value
    case sha256(String)
    /// Use this in the case of needing to not use the payload for signing
    case unsignedPayload
    /// For streaming sha256 payload
    case streamingSha256Payload
    /// For streaming sha256 payload trailer
    case streamingSha256PayloadTrailer
    /// For streaming sigv4a sha256 payload
    case streamingECDSA_P256Sha256Payload
    /// For streaming sigv4a sha256 payload trailer
    case streamingECDSA_P256Sha256PayloadTrailer
    /// For streaming sigv4a sha256 events
    case streamingSha256Events
    /// For streaming unsigned payload trailer
    case streamingUnSignedPayloadTrailer

    public var description: String {
        switch self {
        case .empty:
            return ""
        case .emptySha256:
            return "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
        case .sha256(let hash):
            return hash
        case .unsignedPayload:
            return "UNSIGNED-PAYLOAD"
        case .streamingSha256Payload:
            return "STREAMING-AWS4-HMAC-SHA256-PAYLOAD"
        case .streamingSha256PayloadTrailer:
            return "STREAMING-AWS4-HMAC-SHA256-PAYLOAD-TRAILER"
        case .streamingECDSA_P256Sha256Payload:
            return "STREAMING-AWS4-ECDSA-P256-SHA256-PAYLOAD"
        case .streamingECDSA_P256Sha256PayloadTrailer:
            return "STREAMING-AWS4-ECDSA-P256-SHA256-PAYLOAD-TRAILER"
        case .streamingSha256Events:
            return "STREAMING-AWS4-HMAC-SHA256-EVENTS"
        case .streamingUnSignedPayloadTrailer:
            return "STREAMING-UNSIGNED-PAYLOAD-TRAILER"
        }
    }

    public static func ==(lhs: SignedBodyValue, rhs: SignedBodyValue) -> Bool {
        return lhs.description == rhs.description
    }
}

public enum SigningAlgorithmType {
    case signingV4
    case signingV4Asymmetric
}

extension SignatureType {
    var rawValue: aws_signature_type {
        switch self {
        case .requestHeaders: return AWS_ST_HTTP_REQUEST_HEADERS
        case .requestQueryParams: return AWS_ST_HTTP_REQUEST_QUERY_PARAMS
        case .requestChunk: return AWS_ST_HTTP_REQUEST_CHUNK
        case .requestTrailingHeaders: return AWS_ST_HTTP_REQUEST_TRAILING_HEADERS
        case .requestEvent: return AWS_ST_HTTP_REQUEST_EVENT
        }
    }
}

extension SignedBodyHeaderType {
    var rawValue: aws_signed_body_header_type {
        switch self {
        case .none: return AWS_SBHT_NONE
        case .contentSha256: return AWS_SBHT_X_AMZ_CONTENT_SHA256
        }
    }
}

extension SigningAlgorithmType {
    var rawValue: aws_signing_algorithm {
        switch self {
        case .signingV4: return AWS_SIGNING_ALGORITHM_V4
        case .signingV4Asymmetric: return AWS_SIGNING_ALGORITHM_V4_ASYMMETRIC
        }
    }
}
