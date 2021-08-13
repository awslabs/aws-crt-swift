//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp

public class HttpProxyOptions {
    let rawValue: UnsafeMutablePointer<aws_http_proxy_options>
    public var authType: HttpProxyAuthenticationType = .none
    public var basicAuthUsername: String?
    public var basicAuthPassword: String?
    public var hostName: String
    public var port: UInt16
    public var tlsOptions: TlsConnectionOptions?

    public init(hostName: String, port: UInt16) {
        self.rawValue = allocatePointer()
        self.hostName = hostName
        self.port = port
    }

    deinit {
        rawValue.deinitializeAndDeallocate()
    }
}
