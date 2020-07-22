//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp

public struct HttpClientConnectionProxyOptions {
    internal var rawValue = aws_http_proxy_options()

    public let authType: HttpProxyAuthenticationType
    public let basicAuthUsername: String
    public let basicAuthPassword: String
    public let hostName: String
    public let port: UInt16
    public let tlsOptions: TlsConnectionOptions?

}
