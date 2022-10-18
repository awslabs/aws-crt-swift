//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
public protocol CRTCredentialsProviderStaticConfigOptions {
    var accessKey: String { get set}
    var secret: String { get set}
    var sessionToken: String? { get set}
    var shutDownOptions: ShutDownCallbackOptions? { get set}
}
