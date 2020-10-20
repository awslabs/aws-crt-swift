//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

struct CredentialsProviderProfileOptions {
    public let shutdownOptions: CredentialsProviderShutdownOptions?
    public let configFileNameOverride: String?
    public let profileFileNameOverride: String?
    public let credentialsFileNameOverride: String?

    public init(configFileNameOverride: String? = nil,
                profileFileNameOverride: String? = nil,
                credentialsFileNameOverride: String? = nil,
                shutdownOptions: CredentialsProviderShutdownOptions? = nil) {
        self.configFileNameOverride = configFileNameOverride
        self.profileFileNameOverride = profileFileNameOverride
        self.credentialsFileNameOverride = credentialsFileNameOverride
        self.shutdownOptions = shutdownOptions
    }
}
