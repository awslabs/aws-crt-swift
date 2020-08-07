//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

public final class TlsConnectionOptions {
	private let allocator: Allocator
	var rawValue = aws_tls_connection_options()

	init(_ context: TlsContext, allocator: Allocator) {
		self.allocator = allocator
		aws_tls_connection_options_init_from_ctx(&self.rawValue, context.rawValue)
	}

	deinit {
		aws_tls_connection_options_clean_up(&self.rawValue)
	}

	public func setAlpnList(_ alpnList: String) throws {
		if aws_tls_connection_options_set_alpn_list(&self.rawValue, self.allocator.rawValue, alpnList) != AWS_OP_SUCCESS {
			throw AwsCommonRuntimeError()
		}
	}

	public func setServerName(_ serverName: String) throws {
		var byteCur = serverName.newByteCursor()
		if aws_tls_connection_options_set_server_name(&self.rawValue, self.allocator.rawValue, &byteCur.rawValue) != AWS_OP_SUCCESS {
			throw AwsCommonRuntimeError()
		}
	}
}
