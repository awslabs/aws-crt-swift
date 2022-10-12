//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp
import AwsCCommon
// Todo: try to find a better for a persistent byte cursor
public class HttpProxyOptions {
    private let allocator: Allocator
    let rawValue: UnsafeMutablePointer<aws_http_proxy_options>

    public var authType: HttpProxyAuthenticationType = .none {
        didSet {
            rawValue.pointee.auth_type = authType.rawValue
        }
    }

    private var _basicAuthUsername: AWSStringByteCursor?
    public var basicAuthUsername: String? {
        get {
            if let basicAuthUsername = _basicAuthUsername {
                return basicAuthUsername.string
            }
            return nil
        }
        set(value) {
            if let value = value {
                _basicAuthUsername = AWSStringByteCursor(value, allocator: allocator)
                rawValue.pointee.auth_username = _basicAuthUsername!.byteCursor
            } else {
                _basicAuthUsername = nil
            }
        }
    }

    private var _basicAuthPassword: AWSStringByteCursor?
    public var basicAuthPassword: String? {
        get {
            if let basicAuthPassword = _basicAuthPassword {
                return basicAuthPassword.string
            }
            return nil
        }
        set(value) {
            if let value = value {
                _basicAuthPassword = AWSStringByteCursor(value, allocator: allocator)
                rawValue.pointee.auth_password = _basicAuthPassword!.byteCursor
            } else {
                _basicAuthPassword = nil
            }
        }
    }

    private var _hostName: AWSStringByteCursor
    public var hostName: String {
        get {
            return _hostName.string
        }
        set(value) {
            _hostName = AWSStringByteCursor(value, allocator: allocator)
            rawValue.pointee.host = _hostName.byteCursor
        }
    }

    public var port: UInt16 {
        didSet {
            rawValue.pointee.port = port
        }
    }
    public var tlsOptions: TlsConnectionOptions? {
        didSet {
            rawValue.pointee.tls_options = UnsafePointer(tlsOptions?.rawValue)
        }
    }

    public init(hostName: String, port: UInt16, allocator: Allocator = defaultAllocator) {
        self.allocator = allocator
        self.rawValue = allocator.allocate(capacity: 1)
        self._hostName = AWSStringByteCursor(hostName, allocator: allocator)
        self.port = port

        // Initialize rawValue as well because init doesn't trigger didSet
        rawValue.pointee.port = port
        rawValue.pointee.host = _hostName.byteCursor
    }

    deinit {
        allocator.release(rawValue)
    }
}
