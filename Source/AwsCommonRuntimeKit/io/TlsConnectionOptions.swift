//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

public final class TlsConnectionOptions {
	private let allocator: Allocator
    var rawValue: UnsafeMutablePointer<aws_tls_connection_options>

	init(_ context: TlsContext, allocator: Allocator) {
		self.allocator = allocator
        let connectionOptionsPtr = UnsafeMutablePointer<aws_tls_connection_options>.allocate(capacity: 1)
        //initialize pointer to empty connection options struct
        zeroStruct(connectionOptionsPtr)
        self.rawValue = connectionOptionsPtr
		aws_tls_connection_options_init_from_ctx(rawValue, context.rawValue)
	}

	public func setAlpnList(_ alpnList: String) throws {
		if aws_tls_connection_options_set_alpn_list(rawValue, self.allocator.rawValue, alpnList) != AWS_OP_SUCCESS {
			throw AwsCommonRuntimeError()
		}
	}

	public func setServerName(_ serverName: String) throws {
		var byteCur = serverName.newByteCursor()
		if aws_tls_connection_options_set_server_name(rawValue, self.allocator.rawValue, &byteCur.rawValue) != AWS_OP_SUCCESS {
			throw AwsCommonRuntimeError()
		}
	}

    deinit {
        aws_tls_connection_options_clean_up(rawValue)
        rawValue.deallocate()
    }
}
