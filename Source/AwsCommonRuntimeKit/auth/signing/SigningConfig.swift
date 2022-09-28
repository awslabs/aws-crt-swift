//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth

public struct SigningConfig {
    public typealias ShouldSignHeader = (String) -> Bool
    public let rawValue: aws_signing_config_aws
    public let credentials: CRTCredentials?
    public let credentialsProvider: CRTAWSCredentialsProvider?
    public let expiration: Int64
    public let signedBodyHeader: SignedBodyHeaderType
    public let signedBodyValue: SignedBodyValue
    public let flags: Flags
    public let shouldSignHeader: ShouldSignHeader?
    public let date: AWSDate
    public let service: String
    public let region: String
    public let signatureType: SignatureType
    public let signingAlgorithm: SigningAlgorithmType
    public let configType: SigningConfigType

    public init(credentials: CRTCredentials? = nil,
                credentialsProvider: CRTAWSCredentialsProvider? = nil,
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
                configType: SigningConfigType = .aws) {
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
        rawValue = aws_signing_config_aws(config_type: configType.rawValue,
                                          algorithm: signingAlgorithm.rawValue,
                                          signature_type: signatureType.rawValue,
                                          region: region.awsByteCursor,
                                          service: service.awsByteCursor,
                                          date: date.rawValue.pointee,
                                          should_sign_header: { name, userData -> Bool in
                                              guard let userData = userData,
                                                    let name = name?.pointee.toString()
                                              else {
                                                  return true
                                              }

                                              let callback = userData.assumingMemoryBound(to: ShouldSignHeader?.self)

                                              if let callbackFn = callback.pointee {
                                                  return callbackFn(name)
                                              } else {
                                                  return true
                                              }
                                          },
                                          should_sign_header_ud: fromOptionalPointer(ptr: shouldSignHeader),
                                          flags: flags.rawValue,
                                          signed_body_value: signedBodyValue.rawValue.awsByteCursor,
                                          signed_body_header: signedBodyHeader.rawValue,
                                          credentials: credentials?.rawValue,
                                          credentials_provider: credentialsProvider?.rawValue,
                                          expiration_in_seconds: UInt64(expiration))
    }
}

public extension SigningConfig {
    struct Flags {
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
            rawValue = aws_signing_config_aws.__Unnamed_struct_flags(use_double_uri_encode:
                useDoubleURIEncode.uintValue, should_normalize_uri_path:
                shouldNormalizeURIPath.uintValue, omit_session_token:
                omitSessionToken.uintValue)
        }
    }
}
