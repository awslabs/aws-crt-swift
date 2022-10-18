//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

public protocol CRTCredentialsProviderWebIdentityConfig {
    var shutDownOptions: ShutDownCallbackOptions? {get set}
    var bootstrap: ClientBootstrap {get set}
    var tlsContext: TlsContext {get set}
}
