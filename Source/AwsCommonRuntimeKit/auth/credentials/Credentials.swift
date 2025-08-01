//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth
import Foundation

// We can't mutate this class after initialization. Swift can not verify the sendability due to OpaquePointer,
// So mark it unchecked Sendable
public final class Credentials: @unchecked Sendable {

  let rawValue: OpaquePointer

  init(rawValue: OpaquePointer) {
    self.rawValue = rawValue
    aws_credentials_acquire(rawValue)
  }

  /// Creates a new set of aws credentials
  ///
  /// - Parameters:
  ///   - accessKey: value for the aws access key id field
  ///   - secret: value for the secret access key field
  ///   - sessionToken: (Optional) security token associated with the credentials
  ///   - accountId: (Optional) account id associated with the credentials
  ///   - expiration: (Optional) Point in time after which credentials will no longer be valid.
  ///                 For credentials that do not expire, use nil.
  ///                 If expiration.timeIntervalSince1970 is greater than UInt64.max, it will be converted to nil.
  /// - Throws: CommonRuntimeError.crtError
  public init(
    accessKey: String,
    secret: String,
    sessionToken: String? = nil,
    accountId: String? = nil,
    expiration: Date? = nil
  ) throws {

    let expirationTimeout: UInt64
    if let expiration = expiration,
      expiration.timeIntervalSince1970 < Double(UInt64.max)
    {
      expirationTimeout = UInt64(expiration.timeIntervalSince1970)
    } else {
      expirationTimeout = UInt64.max
    }

    guard
      let rawValue =
        (withByteCursorFromStrings(
          accessKey,
          secret,
          sessionToken,
          accountId
        ) { accessKeyCursor, secretCursor, sessionTokenCursor, accountIdCursor in

          var options = aws_credentials_options()
          options.access_key_id_cursor = accessKeyCursor
          options.secret_access_key_cursor = secretCursor
          options.session_token_cursor = sessionTokenCursor
          options.account_id_cursor = accountIdCursor
          options.expiration_timepoint_seconds = expirationTimeout

          return aws_credentials_new_with_options(allocator.rawValue, &options)
        })
    else {
      throw CommonRunTimeError.crtError(.makeFromLastError())
    }
    self.rawValue = rawValue
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

  /// Gets the session token from the `aws_credentials` instance
  ///
  /// - Returns:`String?`: The AWS Session token or nil
  public func getSessionToken() -> String? {
    let token = aws_credentials_get_session_token(rawValue)
    return token.toOptionalString()
  }

  /// Gets the account id from the `aws_credentials` instance
  ///
  /// - Returns:`String?`: The account id or nil
  public func getAccountId() -> String? {
    let accountId = aws_credentials_get_account_id(rawValue)
    return accountId.toOptionalString()
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
