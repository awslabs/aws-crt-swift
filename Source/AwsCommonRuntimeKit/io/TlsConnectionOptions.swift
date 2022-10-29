//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

public class TlsConnectionOptions: CStruct {
	private let allocator: Allocator
    private var rawValue: UnsafeMutablePointer<aws_tls_connection_options>
	init(_ context: TlsContext, allocator: Allocator) {
		self.allocator = allocator
        self.rawValue = allocator.allocate(capacity: 1)
		aws_tls_connection_options_init_from_ctx(rawValue, context.rawValue)
        #if os(iOS) || os(watchOS)
		rawValue.pointee.timeout_ms = 30_000
        #else
		rawValue.pointee.timeout_ms = 3_000
        #endif
    }

	typealias RawType = aws_tls_connection_options
	func withCStruct<Result>(_ body: (aws_tls_connection_options) -> Result) -> Result {
		return body(rawValue.pointee)
	}

	public func setAlpnList(_ alpnList: String) throws {
		// This function can only fail if allocation fails.
		// We don't handle allocation failure errors anymore.
		_ = aws_tls_connection_options_set_alpn_list(rawValue, self.allocator.rawValue, alpnList)
	}

	public func setServerName(_ serverName: String) throws {
		// This function can only fail if allocation fails.
		// We don't handle allocation failure errors anymore.
		_ = serverName.withByteCursorPointer { serverNameCursorPointer in
			aws_tls_connection_options_set_server_name(rawValue, allocator.rawValue, serverNameCursorPointer)
		}
	}

    deinit {
        aws_tls_connection_options_clean_up(rawValue)
        allocator.release(rawValue)
    }
}
