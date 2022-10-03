//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

public final class TlsConnectionOptions {
	private let allocator: Allocator
    var rawValue: UnsafeMutablePointer<aws_tls_connection_options>

	init(_ context: TlsContext, allocator: Allocator) {
		self.allocator = allocator

        var connectionsPointer: UnsafeMutablePointer<aws_tls_connection_options> = allocatePointer()
		aws_tls_connection_options_init_from_ctx(connectionsPointer, context.rawValue)
        #if os(iOS) || os(watchOS)
        connectionsPointer.pointee.timeout_ms = 30_000
        #else
        connectionsPointer.pointee.timeout_ms = 3_000
        #endif
        self.rawValue = connectionsPointer
	}

	public func setAlpnList(_ alpnList: String) throws {
		if aws_tls_connection_options_set_alpn_list(rawValue, self.allocator.rawValue, alpnList) != AWS_OP_SUCCESS {
			throw AWSCommonRuntimeError.AWSCRTError()
		}
	}

	public func setServerName(_ serverName: String) throws {
		var byteCur = serverName.newByteCursor()
		if aws_tls_connection_options_set_server_name(rawValue,
                                                      self.allocator.rawValue,
                                                      &byteCur.rawValue) != AWS_OP_SUCCESS {
			throw AWSCommonRuntimeError.AWSCRTError()
		}
	}

    deinit {
        aws_tls_connection_options_clean_up(rawValue)
        rawValue.deallocate()
    }
}
