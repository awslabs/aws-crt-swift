//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

public protocol CRTCredentialsProviderChainDefaultConfig {
    var shutDownOptions: ShutDownCallbackOptions? { get set}
    var bootstrap: ClientBootstrap { get set}
}
