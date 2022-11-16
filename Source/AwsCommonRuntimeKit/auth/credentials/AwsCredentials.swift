//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth
import Foundation

public class AwsCredentials {

    let rawValue: OpaquePointer

    init(rawValue: OpaquePointer) {
        self.rawValue = rawValue
        aws_credentials_acquire(rawValue)
    }

    public init(accessKey: String,
                secret: String,
                sessionToken: String?,
                expirationTimeout: UInt64,
                allocator: Allocator = defaultAllocator) throws {
        guard let rawValue = (withByteCursorFromStrings(
                accessKey,
                secret,
                sessionToken) { accessKeyCursor, secretCursor, sessionTokenCursor in
            return aws_credentials_new(allocator.rawValue,
                    accessKeyCursor,
                    secretCursor,
                    sessionTokenCursor, expirationTimeout)
        }) else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        self.rawValue = rawValue
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
        return aws_credentials_get_expiration_timepoint_seconds(rawValue)
    }

    deinit {
        aws_credentials_release(rawValue)
    }
}
