//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

public final class TlsConnectionOptions {
	private let allocator: Allocator
    private var _rawValue: UnsafeMutablePointer<aws_tls_connection_options>
	var rawValue: UnsafePointer<aws_tls_connection_options> { UnsafePointer(_rawValue) }
	init(_ context: TlsContext, allocator: Allocator) {
		self.allocator = allocator
        self._rawValue = allocator.allocate(capacity: 1)
		aws_tls_connection_options_init_from_ctx(_rawValue, context.rawValue)
        #if os(iOS) || os(watchOS)
		_rawValue.pointee.timeout_ms = 30_000
        #else
		_rawValue.pointee.timeout_ms = 3_000
        #endif
    }

	public func setAlpnList(_ alpnList: String) throws {
		if aws_tls_connection_options_set_alpn_list(_rawValue, self.allocator.rawValue, alpnList) != AWS_OP_SUCCESS {
			throw CommonRunTimeError.crtError(.makeFromLastError())
		}
	}

	public func setServerName(_ serverName: String) throws {
		if (serverName.withByteCursorPointer { serverNameCursorPointer in
			aws_tls_connection_options_set_server_name(_rawValue, allocator.rawValue, serverNameCursorPointer)
		}) != AWS_OP_SUCCESS {
			throw CommonRunTimeError.crtError(.makeFromLastError())
		}
	}

    deinit {
        aws_tls_connection_options_clean_up(_rawValue)
        allocator.release(_rawValue)
    }
}
