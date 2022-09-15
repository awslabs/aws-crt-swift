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
       
//        var creds: OpaquePointer?
//        accessKey.withCString{cAccessKey in
//            secret.withCString{cSecret in
//
//
//                let access_key_id = aws_byte_cursor_from_c_str(cAccessKey)
//                let secret_access_key = aws_byte_cursor_from_c_str(cSecret)
//                let secret2 = aws_byte_cursor_from_c_str(cSecret)
//
//                creds = aws_credentials_new(allocator.rawValue,
//                                                    access_key_id,
//                                                    secret_access_key,
//                                                    secret2,expirationTimeout)
//
//            }
//
//        }
//
//        self.rawValue = creds!
        let access_key =  accessKey.newByteCursor()
        let secret_key = secret.newByteCursor()
        let session_token = sessionToken?.newByteCursor() ?? "".newByteCursor()
        
        self.rawValue = aws_credentials_new(allocator.rawValue,
                                            access_key.rawValue,
                                            secret_key.rawValue,
                                            session_token.rawValue, expirationTimeout)
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
