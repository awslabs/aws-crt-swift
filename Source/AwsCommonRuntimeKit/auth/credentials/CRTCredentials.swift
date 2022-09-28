//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth

public final class CRTCredentials {
    let rawValue: OpaquePointer

    public init?(rawValue: OpaquePointer?) {
        guard let rawValue = rawValue else {
            return nil
        }
        self.rawValue = rawValue
        aws_credentials_acquire(rawValue)
    }

    public init(accessKey: String,
                secret: String,
                sessionToken: String?,
                expirationTimeout: UInt64,
                allocator: Allocator = defaultAllocator) {
        rawValue = aws_credentials_new(allocator.rawValue,
                                       accessKey.awsByteCursor,
                                       secret.awsByteCursor,
                                       sessionToken?.awsByteCursor ?? "".awsByteCursor, expirationTimeout)
    }

    /// Gets the access key from the `aws_credentials` instance
    ///
    /// - Returns:`String?`: The AWS Access Key Id or nil
    public func getAccessKey() -> String? {
        let accessKey = aws_credentials_get_access_key_id(rawValue)
        return accessKey.toString()
    }

    /// Gets the secret from the `aws_credentials` instance
    ///
    /// - Returns:`String?`: The AWS Secret or nil
    public func getSecret() -> String? {
        let secret = aws_credentials_get_secret_access_key(rawValue)
        return secret.toString()
    }

    /// Gets the session token from the `aws_credentials` instance
    ///
    /// - Returns:`String?`: The AWS Session token or nil
    public func getSessionToken() -> String? {
        let token = aws_credentials_get_session_token(rawValue)
        return token.toString()
    }

    /// Gets the expiration timeout in seconds from the `aws_credentials` instance
    ///
    /// - Returns:`UInt64`: The timeout in seconds of when the credentials expire
    public func getExpirationTimeout() -> UInt64 {
        aws_credentials_get_expiration_timepoint_seconds(rawValue)
    }

    deinit {
        aws_credentials_release(rawValue)
    }
}
