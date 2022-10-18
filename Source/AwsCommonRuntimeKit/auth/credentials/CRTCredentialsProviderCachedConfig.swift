//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

public protocol CRTCredentialsProviderCachedConfig {
    var shutDownOptions: ShutDownCallbackOptions? {get set}
    var source: CRTAWSCredentialsProvider {get set}
    /// refresh time in ms
    var refreshTime: Int64 {get set}
}
