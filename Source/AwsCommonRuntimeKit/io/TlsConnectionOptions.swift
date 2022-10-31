//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

public struct TlsConnectionOptions: CStruct {
	private let allocator: Allocator
	public var context: TlsContext
	public var alpnList: String?
	public var serverName: String?

	public init(context: TlsContext, alpnList: String? = nil, serverName: String? = nil, allocator: Allocator = defaultAllocator) {
		self.allocator = allocator
		self.context = context
		self.alpnList = alpnList
		self.serverName = serverName
    }

	typealias RawType = aws_tls_connection_options
	func withCStruct<Result>(_ body: (aws_tls_connection_options) -> Result) -> Result {
		var rawValue: UnsafeMutablePointer<aws_tls_connection_options> = allocator.allocate(capacity: 1)
		defer {
			aws_tls_connection_options_clean_up(rawValue)
			allocator.release(rawValue)
		}

		aws_tls_connection_options_init_from_ctx(rawValue, context.rawValue)
		#if os(iOS) || os(watchOS)
		rawValue.pointee.timeout_ms = 30_000
		#else
		rawValue.pointee.timeout_ms = 3_000
		#endif
		if let alpnList = alpnList {
			_ = aws_tls_connection_options_set_alpn_list(rawValue, self.allocator.rawValue, alpnList)
		}
		_ = serverName?.withByteCursorPointer { serverNameCursorPointer in
				aws_tls_connection_options_set_server_name(rawValue, allocator.rawValue, serverNameCursorPointer)
		}
		return body(rawValue.pointee)
	}
}
