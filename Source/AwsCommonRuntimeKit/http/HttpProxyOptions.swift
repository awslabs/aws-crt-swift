//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp
import AwsCCommon

// Todo: try to find a better for a persistent byte cursor
public class HttpProxyOptions {
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

    static func withCPointer<Result>(proxyOptions: HttpProxyOptions?,
                                     _ body: (UnsafePointer<aws_http_proxy_options>?
                                     ) -> Result
    ) -> Result {
        guard let proxyOptions = proxyOptions else {
            return body(nil)
        }
        var cProxyOptions = aws_http_proxy_options()
        cProxyOptions.port = proxyOptions.port
        cProxyOptions.auth_type = proxyOptions.authType.rawValue
        cProxyOptions.tls_options = UnsafePointer(proxyOptions.tlsOptions?.rawValue)

        return withByteCursorFromStrings(proxyOptions.basicAuthUsername ?? "",
                proxyOptions.basicAuthPassword ?? "",
                proxyOptions.hostName) {
            userNamePointer, passwordPointer, hostPointer in
            cProxyOptions.host = hostPointer
            cProxyOptions.auth_username = userNamePointer
            cProxyOptions.auth_password = passwordPointer
            return withUnsafePointer(to: &cProxyOptions) { body($0) }
        }
    }
}
