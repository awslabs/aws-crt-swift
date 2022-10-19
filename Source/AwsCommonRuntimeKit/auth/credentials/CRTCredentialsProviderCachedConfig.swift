//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
// TODO: do we need set here? How is this being used in the SDK?
public protocol CRTCredentialsProviderCachedConfig {
    var shutdownCallback: ShutdownCallback? { get }
    var source: CRTAWSCredentialsProvider { get }
    /// refresh time in ms
    var refreshTime: Int64 { get }
}
