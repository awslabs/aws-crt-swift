//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp
import AwsCCommon

public class HttpProxyOptions: CStruct {
    public var authType: HttpProxyAuthenticationType = .none
    public var basicAuthUsername: String?
    public var basicAuthPassword: String?
    public var hostName: String
    public var port: UInt16
    public var tlsOptions: TlsConnectionOptions?

    public init(hostName: String, port: UInt16) {
        self.hostName = hostName
        self.port = port
    }

    typealias RawType = aws_http_proxy_options
    func withCStruct<Result>(_ body: (aws_http_proxy_options) -> Result) -> Result {
        var cProxyOptions = aws_http_proxy_options()
        cProxyOptions.port = port
        cProxyOptions.auth_type = authType.rawValue
        cProxyOptions.tls_options = tlsOptions?.rawValue

        return withByteCursorFromStrings(basicAuthUsername ?? "",
                                         basicAuthPassword ?? "",
                                         hostName) {
            userNamePointer, passwordPointer, hostPointer in
            cProxyOptions.host = hostPointer
            cProxyOptions.auth_username = userNamePointer
            cProxyOptions.auth_password = passwordPointer
            return body(cProxyOptions)
        }
    }
}
