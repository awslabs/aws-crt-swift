//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

public protocol CRTCredentialsProviderWebIdentityConfig {
    var shutdownCallback: ShutdownCallback? { get }
    var bootstrap: ClientBootstrap { get }
    var tlsContext: TlsContext { get }
}
