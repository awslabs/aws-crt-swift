//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import struct Foundation.TimeInterval

public protocol CRTCredentialsProviderCachedConfig {
    var shutdownCallback: ShutdownCallback? { get }
    var source: CRTAWSCredentialsProvider { get }
    var refreshTime: TimeInterval { get }
}
