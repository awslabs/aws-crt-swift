//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp
import AwsCCommon

public struct HttpProxyOptions: CStruct {
    public var authType: HttpProxyAuthenticationType
    public var basicAuthUsername: String?
    public var basicAuthPassword: String?
    public var hostName: String
    public var port: UInt16
    public var tlsOptions: TlsConnectionOptions?

    public init(hostName: String,
                port: UInt16,
                authType: HttpProxyAuthenticationType = .none,
                basicAuthUsername: String? = nil,
                basicAuthPassword: String? = nil,
                tlsOptions: TlsConnectionOptions? = nil) {
        self.hostName = hostName
        self.port = port
        self.authType = authType
        self.basicAuthUsername = basicAuthUsername
        self.basicAuthPassword = basicAuthPassword
        self.tlsOptions = tlsOptions
    }

    typealias RawType = aws_http_proxy_options
    func withCStruct<Result>(_ body: (aws_http_proxy_options) -> Result) -> Result {
        var cProxyOptions = aws_http_proxy_options()
        cProxyOptions.port = port
        cProxyOptions.auth_type = authType.rawValue

        return withByteCursorFromStrings(basicAuthUsername,
                                         basicAuthPassword,
                                         hostName) {
            userNamePointer, passwordPointer, hostPointer in
            cProxyOptions.host = hostPointer
            cProxyOptions.auth_username = userNamePointer
            cProxyOptions.auth_password = passwordPointer
            return withOptionalCStructPointer(to: tlsOptions) { tlsOptionsPointer in
                cProxyOptions.tls_options = tlsOptionsPointer
                return body(cProxyOptions)
            }
        }
    }
}
