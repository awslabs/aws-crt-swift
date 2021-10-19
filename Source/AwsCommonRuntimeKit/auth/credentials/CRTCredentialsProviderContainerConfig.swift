//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

public protocol CRTCredentialsProviderContainerConfig {
    var shutDownOptions: CRTCredentialsProviderShutdownOptions? {get set}
    var bootstrap: ClientBootstrap {get set}
    var tlsContext: TlsContext {get set}
    var authToken: String? {get set}
    var pathAndQuery: String? {get set}
    var host: String? {get set}
}
