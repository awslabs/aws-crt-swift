//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

public protocol CRTCredentialsProviderProfileOptions {
    var shutdownOptions: CRTCredentialsProviderShutdownOptions? {get set}
    var configFileNameOverride: String? {get set}
    var profileNameOverride: String? {get set}
    var credentialsFileNameOverride: String? {get set}
}
