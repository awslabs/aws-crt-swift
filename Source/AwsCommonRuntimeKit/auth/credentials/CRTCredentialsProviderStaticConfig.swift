//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

public protocol CRTCredentialsProviderStaticConfigOptions {
    var accessKey: String { get }
    var secret: String { get }
    var sessionToken: String? { get }
    var shutdownCallback: ShutdownCallback? { get }
}
