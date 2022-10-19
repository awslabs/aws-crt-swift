//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

public protocol CRTCredentialsProviderSTSConfig {
    var shutDownOptions: ShutDownCallbackOptions? { get }
    var bootstrap: ClientBootstrap { get }
    var tlsContext: TlsContext { get }
    var credentialsProvider: CRTAWSCredentialsProvider { get }
    var roleArn: String { get }
    var sessionName: String { get }
    var durationSeconds: UInt16 { get }
}
