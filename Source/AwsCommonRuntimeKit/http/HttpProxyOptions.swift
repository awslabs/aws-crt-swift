//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp
import AwsCCommon
// Todo: try to find a better for a persistent byte cursor
public class HttpProxyOptions {
    private let allocator: Allocator
    private var rawValue: UnsafeMutablePointer<aws_http_proxy_options>
    private var _basicAuthUsername: AWSStringByteCursor?
    private var _basicAuthPassword: AWSStringByteCursor?
    private var _hostName: AWSStringByteCursor?

    public var authType: HttpProxyAuthenticationType = .none
    public var basicAuthUsername: String?
    public var basicAuthPassword: String?
    public var hostName: String
    public var port: UInt16
    public var tlsOptions: TlsConnectionOptions?

    public init(hostName: String, port: UInt16, allocator: Allocator = defaultAllocator) {
        self.allocator = allocator
        self.rawValue = allocator.allocate(capacity: 1)
        self.hostName = hostName
        self.port = port
    }

    func getRawValue() -> UnsafeMutablePointer<aws_http_proxy_options> {
        _basicAuthUsername = AWSStringByteCursor(basicAuthUsername ?? "", allocator: allocator)
        _basicAuthPassword = AWSStringByteCursor(basicAuthPassword ?? "", allocator: allocator)
        _hostName = AWSStringByteCursor(hostName, allocator: allocator)
        rawValue.pointee.port = port
        rawValue.pointee.host = _hostName!.byteCursor
        rawValue.pointee.auth_username = _basicAuthUsername!.byteCursor
        rawValue.pointee.auth_password = _basicAuthPassword!.byteCursor
        rawValue.pointee.tls_options = UnsafePointer(tlsOptions?.rawValue)
        rawValue.pointee.auth_type = authType.rawValue

        return rawValue
    }

    deinit {
        allocator.release(rawValue)
    }
}
