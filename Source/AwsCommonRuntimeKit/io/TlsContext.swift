//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

public class TlsContext {
    var rawValue: UnsafeMutablePointer<aws_tls_ctx>

    public init(options: TlsContextOptions, mode: TlsMode, allocator: Allocator = defaultAllocator) throws {
        guard let rawValue = (options.withCPointer { optionsPointer in
            let context: UnsafeMutablePointer<aws_tls_ctx>?
            switch mode {
            case .client:
                context = aws_tls_client_ctx_new(allocator.rawValue, optionsPointer)
            case .server:
                context = aws_tls_server_ctx_new(allocator.rawValue, optionsPointer)
            }
            return context
        })  else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        self.rawValue = rawValue
    }

    deinit {
        aws_tls_ctx_release(rawValue)
    }
}
