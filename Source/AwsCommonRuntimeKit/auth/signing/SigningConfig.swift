//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth

// TODO: verify callback logic, fix pointers, and maybe error handling
public struct SigningConfig: CStruct {
    public typealias ShouldSignHeader = (String) -> Bool
    public var credentials: Credentials?
    public var credentialsProvider: CredentialsProvider?
    public var expiration: Int64
    public var signedBodyHeader: SignedBodyHeaderType
    public var signedBodyValue: SignedBodyValue
    public var flags: Flags
    public var shouldSignHeader: ShouldSignHeader?
    public var date: AWSDate
    public var service: String
    public var region: String
    public var signatureType: SignatureType
    public var signingAlgorithm: SigningAlgorithmType
    public var configType: SigningConfigType

    public init(credentials: Credentials? = nil,
                credentialsProvider: CredentialsProvider? = nil,
                date: AWSDate,
                service: String,
                region: String,
                expiration: Int64 = 0,
                signedBodyHeader: SignedBodyHeaderType = .none,
                signedBodyValue: SignedBodyValue = SignedBodyValue.empty,
                flags: Flags = Flags(),
                shouldSignHeader: ShouldSignHeader? = nil,
                signatureType: SignatureType = .requestHeaders,
                signingAlgorithm: SigningAlgorithmType = .signingV4,
                configType: SigningConfigType = .aws,
                allocator: Allocator = defaultAllocator) {

        self.credentials = credentials
        self.credentialsProvider = credentialsProvider
        self.expiration = expiration
        self.date = date
        self.service = service
        self.region = region
        self.signedBodyHeader = signedBodyHeader
        self.signedBodyValue = signedBodyValue
        self.flags = flags
        self.shouldSignHeader = shouldSignHeader
        self.signatureType = signatureType
        self.signingAlgorithm = signingAlgorithm
        self.configType = configType
    }

    typealias RawType = aws_signing_config_aws
    func withCStruct<Result>(_ body: (aws_signing_config_aws) -> Result) -> Result {
        var cSigningConfig = aws_signing_config_aws()
        cSigningConfig.config_type = configType.rawValue
        cSigningConfig.algorithm = signingAlgorithm.rawValue
        cSigningConfig.signature_type = signatureType.rawValue

        cSigningConfig.date = date.rawValue.pointee
        //TODO: fix callback
        cSigningConfig.should_sign_header = { (name, userData) -> Bool in
            guard let name = name?.pointee.toString()
            else {
                return true
            }
            let callback = userData!.assumingMemoryBound(to: ShouldSignHeader?.self)
            if let callbackFn = callback.pointee {
                return callbackFn(name)
            } else {
                return true
            }
        }
        cSigningConfig.should_sign_header_ud = fromOptionalPointer(ptr: shouldSignHeader)
        cSigningConfig.flags = flags.rawValue
        cSigningConfig.signed_body_header = signedBodyHeader.rawValue
        cSigningConfig.credentials = credentials?.rawValue
        cSigningConfig.credentials_provider = credentialsProvider?.rawValue
        cSigningConfig.expiration_in_seconds = UInt64(expiration)
        return withByteCursorFromStrings(region,
                                         service,
                                         signedBodyValue.rawValue) { regionCursor,
                                                                     serviceCursor,
                                                                     signedBodyValueCursor in
            cSigningConfig.region = regionCursor
            cSigningConfig.service = serviceCursor
            cSigningConfig.signed_body_value = signedBodyValueCursor
            return body(cSigningConfig)
        }
    }
}

extension SigningConfig {
    public struct Flags {
         let rawValue: aws_signing_config_aws.__Unnamed_struct_flags

         /// We assume the uri will be encoded once in preparation for transmission.  Certain services
         /// do not decode before checking signature, requiring us to actually double-encode the uri in the canonical
         /// request in order to pass a signature check.
         let useDoubleURIEncode: Bool

         /// Controls whether or not the uri paths should be normalized when building the canonical request
         let shouldNormalizeURIPath: Bool

         /// Should the "X-Amz-Security-Token" query param be omitted?
         /// Normally, this parameter is added during signing if the credentials have a session token.
         /// The only known case where this should be true is when signing a websocket handshake to IoT Core.
         let omitSessionToken: Bool

        public init(useDoubleURIEncode: Bool = true,
                    shouldNormalizeURIPath: Bool = true,
                    omitSessionToken: Bool = false) {
            self.useDoubleURIEncode = useDoubleURIEncode
            self.shouldNormalizeURIPath = shouldNormalizeURIPath
            self.omitSessionToken = omitSessionToken
            self.rawValue = aws_signing_config_aws.__Unnamed_struct_flags(use_double_uri_encode:
                useDoubleURIEncode.uintValue, should_normalize_uri_path:
                shouldNormalizeURIPath.uintValue, omit_session_token:
                omitSessionToken.uintValue)
        }
     }
}
