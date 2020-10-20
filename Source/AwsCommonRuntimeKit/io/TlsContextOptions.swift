//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

public final class TlsContextOptions {
    var rawValue: UnsafeMutablePointer<aws_tls_ctx_options>

	public static func isAlpnSupported() -> Bool {
		return aws_tls_is_alpn_available()
	}

	public init(defaultClientWithAllocator allocator: Allocator = defaultAllocator) {
        let optionsPtr = UnsafeMutablePointer<aws_tls_ctx_options>.allocate(capacity: 1)
        zeroStruct(optionsPtr)
        self.rawValue = optionsPtr
		aws_tls_ctx_options_init_default_client(rawValue, allocator.rawValue)
	}

    #if os(macOS)
	public init(clientWithMtlsCertificatePath certPath: String, keyPath: String, allocator: Allocator = defaultAllocator) throws {
        let ptr = UnsafeMutablePointer<aws_byte_cursor>.allocate(capacity: 1)
        ptr.initialize(to: keyPath.awsByteCursor)
        let optionsPtr = UnsafeMutablePointer<aws_tls_ctx_options>.allocate(capacity: 1)
        zeroStruct(optionsPtr)
        self.rawValue = optionsPtr
        if aws_tls_ctx_options_init_client_mtls_pkcs12_from_path(rawValue, allocator.rawValue, certPath, ptr) != AWS_OP_SUCCESS {
			throw AwsCommonRuntimeError()
		}
    
	}

	public init(clientWithMtlsCert cert: inout ByteCursor, key: inout ByteCursor, allocator: Allocator = defaultAllocator) throws {
        let optionsPtr = UnsafeMutablePointer<aws_tls_ctx_options>.allocate(capacity: 1)
        zeroStruct(optionsPtr)
        self.rawValue = optionsPtr
        if aws_tls_ctx_options_init_client_mtls_pkcs12(rawValue, allocator.rawValue, &cert.rawValue, &key.rawValue) != AWS_OP_SUCCESS {
			throw AwsCommonRuntimeError()
		}
	}
    #endif

	#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
	public init(clientWithMtlsPkcs12Path path: String, password: String, allocator: Allocator = defaultAllocator) throws {
        let optionsPtr = UnsafeMutablePointer<aws_tls_ctx_options>.allocate(capacity: 1)
        zeroStruct(optionsPtr)
        self.rawValue = optionsPtr
		var passwordCursor = password.newByteCursor()
		if aws_tls_ctx_options_init_client_mtls_pkcs12_from_path(rawValue, allocator.rawValue, path, &passwordCursor.rawValue) != AWS_OP_SUCCESS {
			throw AwsCommonRuntimeError()
		}
	}
	#endif

	public func overrideDefaultTrustStore(caPath: String, caFile: String) throws {
		if aws_tls_ctx_options_override_default_trust_store_from_path(rawValue, caPath, caFile) != AWS_OP_SUCCESS {
			throw AwsCommonRuntimeError()
		}
	}

	public func overrideDefaultTrustStore(cert: inout ByteCursor) throws {
		if aws_tls_ctx_options_override_default_trust_store(rawValue, &cert.rawValue) != AWS_OP_SUCCESS {
			throw AwsCommonRuntimeError()
		}
	}

	public func setAlpnList(_ alpnList: String) throws {
		if aws_tls_ctx_options_set_alpn_list(rawValue, alpnList) != AWS_OP_SUCCESS {
			throw AwsCommonRuntimeError()
		}
	}

	public func setVerifyPeer(_ verifyPeer: Bool) {
		aws_tls_ctx_options_set_verify_peer(rawValue, verifyPeer)
	}

	deinit {
		aws_tls_ctx_options_clean_up(rawValue)
        rawValue.deallocate()
	}
}
