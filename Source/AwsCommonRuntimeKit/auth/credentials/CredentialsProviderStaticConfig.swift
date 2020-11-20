//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

public struct CredentialsProviderStaticConfigOptions {
    public let accessKey: String
    public let secret: String
    public let sessionToken: String
    public let shutDownOptions: CredentialsProviderShutdownOptions?

    public init(accessKey: String,
                secret: String,
                sessionToken: String,
                shutDownOptions: CredentialsProviderShutdownOptions? = nil) {
        self.accessKey = accessKey
        self.secret = secret
        self.sessionToken = sessionToken
        self.shutDownOptions = shutDownOptions
    }
}
