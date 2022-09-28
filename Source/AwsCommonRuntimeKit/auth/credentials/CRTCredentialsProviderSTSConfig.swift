//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol CRTCredentialsProviderSTSConfig {
    var shutDownOptions: CRTCredentialsProviderShutdownOptions? { get set }
    var bootstrap: ClientBootstrap { get set }
    var tlsContext: TlsContext { get set }
    var credentialsProvider: CRTAWSCredentialsProvider { get set }
    var roleArn: String { get set }
    var sessionName: String { get set }
    var durationSeconds: UInt16 { get set }
}
