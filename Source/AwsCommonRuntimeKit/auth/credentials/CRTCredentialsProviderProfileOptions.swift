//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

public protocol CRTCredentialsProviderProfileOptions {
    var shutdownOptions: ShutDownCallbackOptions? { get }
    var configFileNameOverride: String? { get }
    var profileFileNameOverride: String? { get }
    var credentialsFileNameOverride: String? { get }
}
