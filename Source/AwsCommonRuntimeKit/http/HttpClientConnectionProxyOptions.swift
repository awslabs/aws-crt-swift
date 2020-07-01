//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

public struct HttpClientConnectionProxyOptions {
    public let authType: AwsHttpProxyAuthenticationType
    public let basicAuthUsername: String
    public let basicAuthPassword: String
    public let hostName: String
    public let port: UInt16
    public let tlsOptions: TlsConnectionOptions?
}