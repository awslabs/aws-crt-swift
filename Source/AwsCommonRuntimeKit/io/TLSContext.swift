//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

public class TLSContext {
  var rawValue: UnsafeMutablePointer<aws_tls_ctx>

  /// The minimum TLS version that was configured, if any. Used for metrics tracking.
  internal let minimumTLSVersion: TLSVersion?

  /// The certificate source automatically determined from TLSContextOptions. Used for metrics tracking.
  internal let certificateSource: CertificateSource?

  public init(options: TLSContextOptions, mode: TLSMode) throws {
    self.minimumTLSVersion = options.minimumTLSVersion
    self.certificateSource = options.certificateSource
    guard
      let rawValue =
        (options.withCPointer { optionsPointer -> UnsafeMutablePointer<aws_tls_ctx>? in
          switch mode {
          case .client:
            return aws_tls_client_ctx_new(allocator.rawValue, optionsPointer)
          case .server:
            return aws_tls_server_ctx_new(allocator.rawValue, optionsPointer)
          }
        })
    else {
      throw CommonRunTimeError.crtError(.makeFromLastError())
    }
    self.rawValue = rawValue
  }

  deinit {
    aws_tls_ctx_release(rawValue)
  }
}

public enum TLSMode {
  case client
  case server
}
