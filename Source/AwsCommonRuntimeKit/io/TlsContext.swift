//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

public final class TlsContext {
    private let allocator: Allocator
    var rawValue: UnsafeMutablePointer<aws_tls_ctx>

    /// Take a reference to keep it alive
    private let tlsContextOptions: TlsContextOptions
    public init(options: TlsContextOptions, mode: TlsMode, allocator: Allocator = defaultAllocator) throws {
        self.tlsContextOptions = options
        let context: UnsafeMutablePointer<aws_tls_ctx>?
        switch mode {
        case .client:
            context = aws_tls_client_ctx_new(allocator.rawValue, options.rawValue)
        case .server:
            context = aws_tls_server_ctx_new(allocator.rawValue, options.rawValue)
        }
        guard let rawValue = context else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        self.allocator = allocator
        self.rawValue = rawValue
    }

    deinit {
        aws_tls_ctx_release(rawValue)
    }

    public func newConnectionOptions() -> TlsConnectionOptions {
        return TlsConnectionOptions(self, allocator: self.allocator)
    }
}
