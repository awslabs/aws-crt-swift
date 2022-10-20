//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import struct Foundation.TimeInterval

public protocol CRTCredentialsProviderSTSConfig {
    var shutdownCallback: ShutdownCallback? { get }
    var bootstrap: ClientBootstrap { get }
    var tlsContext: TlsContext { get }
    var credentialsProvider: CRTAWSCredentialsProvider { get }
    var roleArn: String { get }
    var sessionName: String { get }
    var durationSeconds: TimeInterval { get }
}
