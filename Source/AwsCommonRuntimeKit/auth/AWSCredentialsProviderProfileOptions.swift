//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import Foundation

struct AWSCredentialsProviderProfileOptions {
    public let shutdownOptions: AWSCredentialsProviderShutdownOptions
    public let configFileNameOverride: String
    public let profileFileNameOverride: String
    public let credentialsFileNameOverride: String
    
    public init(shutdownOptions: AWSCredentialsProviderShutdownOptions,
                configFileNameOverride: String,
                profileFileNameOverride: String,
                credentialsFileNameOverride: String) {
        self.shutdownOptions = shutdownOptions
        self.configFileNameOverride = configFileNameOverride
        self.profileFileNameOverride = profileFileNameOverride
        self.credentialsFileNameOverride = credentialsFileNameOverride
    }
}
