//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth
import Foundation

public final class Credentials {

    let rawValue: OpaquePointer

    // TODO: remove this property once aws-c-auth supports account_id
    private let accountId: String?

    init(rawValue: OpaquePointer, accountId: String? = nil) {
        self.rawValue = rawValue
        aws_credentials_acquire(rawValue)
        self.accountId = accountId
    }

    /// Creates a new set of aws credentials
    ///
    /// - Parameters:
    ///   - accessKey: value for the aws access key id field
    ///   - secret: value for the secret access key field
    ///   - sessionToken: (Optional) security token associated with the credentials
    ///   - accountId: (Optional) the account ID for the resolved credentials, if known
    ///   - expiration: (Optional) Point in time after which credentials will no longer be valid.
    ///                 For credentials that do not expire, use nil.
    ///                 If expiration.timeIntervalSince1970 is greater than UInt64.max, it will be converted to nil.
    /// - Throws: CommonRuntimeError.crtError
    public init(accessKey: String,
                secret: String,
                accountId: String? = nil,
                sessionToken: String? = nil,
                expiration: Date? = nil) throws {

        let expirationTimeout: UInt64
        if let expiration = expiration,
           expiration.timeIntervalSince1970 < Double(UInt64.max) {
            expirationTimeout = UInt64(expiration.timeIntervalSince1970)
        } else {
            expirationTimeout = UInt64.max
        }

        guard let rawValue = (withByteCursorFromStrings(
            accessKey,
            secret,
            sessionToken) { accessKeyCursor, secretCursor, sessionTokenCursor in

            return aws_credentials_new(
                allocator.rawValue,
                accessKeyCursor,
                secretCursor,
                sessionTokenCursor,
                expirationTimeout)
        }) else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        self.rawValue = rawValue
        self.accountId = accountId
    }

    /// Gets the access key from the `aws_credentials` instance
    ///
    /// - Returns:`String?`: The AWS Access Key Id or nil
    public func getAccessKey() -> String? {
        let accessKey = aws_credentials_get_access_key_id(rawValue)
        return accessKey.toOptionalString()
    }

    /// Gets the secret from the `aws_credentials` instance
    ///
    /// - Returns:`String?`: The AWS Secret or nil
    public func getSecret() -> String? {
        let secret = aws_credentials_get_secret_access_key(rawValue)
        return secret.toOptionalString()
    }

    /// Gets the account ID from the `Credentials`, if any.
    ///
    /// Temporarily, `accountId` is backed by a Swift instance variable.
    /// In the future, when the C implementation implements `account_id` the implementation will get account ID from the `aws_credentials` instance.
    /// - Returns:`String?`: The AWS `accountId` or nil
    public func getAccountId() -> String? {
        accountId
    }

    /// Gets the session token from the `aws_credentials` instance
    ///
    /// - Returns:`String?`: The AWS Session token or nil
    public func getSessionToken() -> String? {
        let token = aws_credentials_get_session_token(rawValue)
        return token.toOptionalString()
    }

    /// Gets the expiration timeout from the `aws_credentials` instance
    ///
    /// - Returns:`Data?`: The timeout in seconds of when the credentials expire.
    ///                     It will return nil if credentials never expire
    public func getExpiration() -> Date? {
        let seconds = aws_credentials_get_expiration_timepoint_seconds(rawValue)
        if seconds == UInt64.max {
            return nil
        }
        return Date(timeIntervalSince1970: TimeInterval(seconds))
    }

    deinit {
        aws_credentials_release(rawValue)
    }
}
