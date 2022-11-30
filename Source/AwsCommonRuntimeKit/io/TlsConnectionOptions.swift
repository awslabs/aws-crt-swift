//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

public struct TlsConnectionOptions: CStruct {
    private let allocator: Allocator
    public var context: TlsContext
    public var alpnList: [String]?
    public var serverName: String?

    public init(context: TlsContext, alpnList: [String]? = nil, serverName: String? = nil, allocator: Allocator = defaultAllocator) {
        self.allocator = allocator
        self.context = context
        self.alpnList = alpnList
        self.serverName = serverName
    }

    typealias RawType = aws_tls_connection_options
    func withCStruct<Result>(_ body: (aws_tls_connection_options) -> Result) -> Result {
        var rawValue = aws_tls_connection_options()
        return withUnsafeMutablePointer(to: &rawValue) { tlsConnectionsOptionsPointer in
            aws_tls_connection_options_init_from_ctx(tlsConnectionsOptionsPointer, context.rawValue)
            defer {
                aws_tls_connection_options_clean_up(tlsConnectionsOptionsPointer)
            }
            #if os(iOS) || os(watchOS)
            tlsConnectionsOptionsPointer.pointee.timeout_ms = 30_000
            #else
            tlsConnectionsOptionsPointer.pointee.timeout_ms = 3_000
            #endif
            if let alpnList = alpnList {
                _ = aws_tls_connection_options_set_alpn_list(tlsConnectionsOptionsPointer, self.allocator.rawValue, alpnList.joined(separator: ";"))
            }
            _ = serverName?.withByteCursorPointer { serverNameCursorPointer in
                aws_tls_connection_options_set_server_name(tlsConnectionsOptionsPointer, allocator.rawValue, serverNameCursorPointer)
            }
            return body(tlsConnectionsOptionsPointer.pointee)
        }
    }
}
