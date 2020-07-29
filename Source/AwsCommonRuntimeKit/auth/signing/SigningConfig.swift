//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth
import Foundation

struct SigningConfig {
    public typealias ShouldSignHeader = (String) -> Bool
    public let rawValue: aws_signing_config_aws
    public let credentials: Credentials?
    public let credentialsProvider: CredentialsProvider?
    public let expiration: Int64
    public let signedBodyHeader: SignedBodyHeaderType
    public let signedBodyValue: SignedBodyValueType
    public let flags: Flags
    public let shouldSignHeader: ShouldSignHeader?
    public let date: Date
    public let service: String
    public let region: String
    public let signatureType: SignatureType
    public let signingAlgorithm: SigningAlgorithmType
    public let configType: SigningConfigType
    
    public init(credentials: Credentials? = nil,
                credentialsProvider: CredentialsProvider? = nil,
                expiration: Int64,
                date: Date,
                service: String,
                region: String,
                signedBodyHeader: SignedBodyHeaderType = .contentSha256,
                signedBodyValue: SignedBodyValueType = .empty,
                flags: Flags = Flags(),
                shouldSignHeader: ShouldSignHeader? = .none,
                signatureType: SignatureType = .requestChunk,
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
        let pointer = UnsafeMutablePointer<ShouldSignHeader>.allocate(capacity: 1)
        if let shouldSignHeader = shouldSignHeader {
            pointer.initialize(to: shouldSignHeader)
        }
        self.rawValue = aws_signing_config_aws(config_type: configType.rawValue,
                                               algorithm: signingAlgorithm.rawValue,
                                               signature_type: signatureType.rawValue,
                                               region: region.awsByteCursor,
                                               service: service.awsByteCursor,
                                               date: date.awsDateTime,
                                               should_sign_header: { (name, userData) -> Bool in
                                                
                                                guard let userData = userData,
                                                    let name = name?.pointee.toString() else {
                                                    return false
                                                }
                                                
                                                let callback = userData.bindMemory(to: ShouldSignHeader.self, capacity: 1)
                                                defer {
                                                    callback.deinitializeAndDeallocate()
                                                }
                                                return callback.pointee(name)
                                                },
                                               should_sign_header_ud: pointer,
                                               flags: flags.rawValue,
                                               signed_body_value: signedBodyValue.rawValue,
                                               signed_body_header: signedBodyHeader.rawValue,
                                               credentials: credentials?.rawValue,
                                               credentials_provider: credentialsProvider?.rawValue,
                                               expiration_in_seconds: UInt64(expiration))
    }
}

extension SigningConfig {
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
                     omitSessionToken: Bool = true) {
             self.useDoubleURIEncode = useDoubleURIEncode
             self.shouldNormalizeURIPath = shouldNormalizeURIPath
             self.omitSessionToken = omitSessionToken
             self.rawValue = aws_signing_config_aws.__Unnamed_struct_flags(use_double_uri_encode: useDoubleURIEncode.uintValue,
                                                                           should_normalize_uri_path: shouldNormalizeURIPath.uintValue,
                                                                           omit_session_token: omitSessionToken.uintValue)
         }
     }
}
