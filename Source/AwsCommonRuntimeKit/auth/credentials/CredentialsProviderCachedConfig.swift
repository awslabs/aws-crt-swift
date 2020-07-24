//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import Foundation

struct CredentialsProviderCachedConfig {
    
    public let shutDownOptions: CredentialsProviderShutdownOptions
    public let source: CredentialsProvider
    public let refreshTimeMs: Int64
    
    public init(shutDownOptions: CredentialsProviderShutdownOptions,
                source: CredentialsProvider,
                refreshTimeMs: Int64) {
        self.shutDownOptions = shutDownOptions
        self.source = source
        self.refreshTimeMs = refreshTimeMs
    }
    

}
