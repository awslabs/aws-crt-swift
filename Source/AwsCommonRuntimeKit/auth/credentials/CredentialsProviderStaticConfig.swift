//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth

class CredentialsProviderStaticConfigOptions {
    public let rawValue: UnsafeMutablePointer<aws_credentials_provider_static_options>
    public let shutdownOptions: CredentialsProviderShutdownOptions?
    
    public init(accessKey: String,
                secret: String,
                sessionToken: String,
                shutDownOptions: CredentialsProviderShutdownOptions?) {
        let pointer = UnsafeMutablePointer<aws_credentials_provider_static_options>.allocate(capacity: 1)
        let shutDownOptionsC = AWSCredentialsProvider.setUpShutDownOptions(shutDownOptions: shutDownOptions)
        pointer.pointee = aws_credentials_provider_static_options(shutdown_options: shutDownOptionsC,
                                                                  access_key_id: accessKey.awsByteCursor,
                                                                  secret_access_key: secret.awsByteCursor,
                                                                  session_token: sessionToken.awsByteCursor)
        self.rawValue = pointer
        self.shutdownOptions = shutDownOptions
    }
    
    deinit {
        rawValue.deinitializeAndDeallocate()
    }
}
