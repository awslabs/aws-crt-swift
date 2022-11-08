//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

public class TlsContext {
    var rawValue: UnsafeMutablePointer<aws_tls_ctx>

    public init(options: TlsContextOptions, mode: TlsMode, allocator: Allocator = defaultAllocator) throws {
        guard let rawValue = (options.withCPointer { optionsPointer in
            switch mode {
            case .client:
                return aws_tls_client_ctx_new(allocator.rawValue, optionsPointer)
            case .server:
                return aws_tls_server_ctx_new(allocator.rawValue, optionsPointer)
            }
        })  else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        self.rawValue = rawValue
    }

    deinit {
        aws_tls_ctx_release(rawValue)
    }
}

public enum TlsMode {
    case client
    case server
}
