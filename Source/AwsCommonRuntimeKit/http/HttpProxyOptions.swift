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

    private var _basicAuthUsername: AWSString?
    public var basicAuthUsername: String? {
        get {
            if let str = _basicAuthUsername {
                return String(awsString: str.rawValue)
            }
            return nil
        }
        set(value) {
            if let value = value {
                _basicAuthUsername = AWSString(value, allocator: allocator)
                rawValue.pointee.auth_username = aws_byte_cursor_from_string(_basicAuthUsername?.rawValue)
            } else {
                _basicAuthUsername = nil
            }
        }
    }

    private var _basicAuthPassword: AWSString?
    public var basicAuthPassword: String? {
        get {
            if let str = _basicAuthPassword {
                return String(awsString: str.rawValue)
            }
            return nil
        }
        set(value) {
            if let value = value {
                _basicAuthPassword = AWSString(value, allocator: allocator)
                rawValue.pointee.auth_password = aws_byte_cursor_from_string(_basicAuthPassword?.rawValue)
            } else {
                _basicAuthPassword = nil
            }
        }
    }

    private var _hostName: AWSString
    public var hostName: String {
        get {
            // As the encoding is Utf-8 this should never fail.
            return String(awsString: _hostName.rawValue)!
        }
        set(value) {
            _hostName = AWSString(value, allocator: allocator)
            rawValue.pointee.host = aws_byte_cursor_from_string(_hostName.rawValue)
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
        self._hostName = AWSString(hostName, allocator: allocator)
        self.port = port

        // Initialize rawValue as well because init doesn't trigger didSet
        rawValue.pointee.port = port
        rawValue.pointee.host = aws_byte_cursor_from_string(_hostName.rawValue)
    }

    deinit {
        allocator.release(rawValue)
    }
}
