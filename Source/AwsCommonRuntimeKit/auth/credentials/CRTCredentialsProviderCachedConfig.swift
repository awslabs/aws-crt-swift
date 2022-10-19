//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

public protocol CRTCredentialsProviderCachedConfig {
    var shutdownCallback: ShutdownCallback? { get }
    var source: CRTAWSCredentialsProvider { get }
    /// refresh time in ms
    var refreshTime: Int64 { get }
}
