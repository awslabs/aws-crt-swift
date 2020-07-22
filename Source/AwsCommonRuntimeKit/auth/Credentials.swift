//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth

public final class Credentials {
    
    let rawValue: OpaquePointer
    
    public init(rawValue: OpaquePointer) {
        self.rawValue = rawValue
    }
    
    public init(accessKey: String,
                secret: String,
                sessionToken: String,
                expirationTimeout: Int,
                allocator: Allocator = defaultAllocator) {
        self.rawValue = aws_credentials_new(allocator.rawValue,
                                            accessKey.awsByteCursor,
                                            secret.awsByteCursor,
                                            sessionToken.awsByteCursor, UInt64(expirationTimeout))
    }
    
    /// Gets the access key from the `aws_credentials` instance
    ///
    /// - Returns:`String?`: The AWS Access Key Id or nil
    public func getAccessKey() -> String? {
        let accessKey = aws_credentials_get_access_key_id(rawValue)
        guard let accessKeyUnwrapped = accessKey.toString()  else {
            return nil
        }
        return accessKeyUnwrapped
    }
    
    /// Gets the secret from the `aws_credentials` instance
    ///
    /// - Returns:`String?`: The AWS Secret or nil
    public func getSecret() -> String? {
        let secret = aws_credentials_get_secret_access_key(rawValue)
        guard let secretUnwrapped = secret.toString() else {
            return nil
        }
        
        return secretUnwrapped
    }
    
    /// Gets the session token from the `aws_credentials` instance
    ///
    /// - Returns:`String?`: The AWS Session token or nil
    public func getSessionToken() -> String? {
        let token = aws_credentials_get_session_token(rawValue)
        guard let tokenUnwrapped = token.toString() else {
            return nil
        }
        
        return tokenUnwrapped
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
