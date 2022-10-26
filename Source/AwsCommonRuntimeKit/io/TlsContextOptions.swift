//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo
public final class TlsContextOptions {
    private let allocator: Allocator
    var rawValue: UnsafeMutablePointer<aws_tls_ctx_options>
    public static func isAlpnSupported() -> Bool {
        return aws_tls_is_alpn_available()
    }

    public init(defaultClientWithAllocator allocator: Allocator = defaultAllocator) {
        self.allocator = allocator
        self.rawValue = allocator.allocate(capacity: 1)
        aws_tls_ctx_options_init_default_client(rawValue, allocator.rawValue)
    }

    #if os(macOS)
    public init(clientWithMtlsCertificatePath certPath: String,
                keyPath: String,
                allocator: Allocator = defaultAllocator) throws {
        self.allocator = allocator
        self.rawValue = allocator.allocate(capacity: 1)
        if (keyPath.withByteCursorPointer { keyPathPointer in
            aws_tls_ctx_options_init_client_mtls_pkcs12_from_path(rawValue,
                    allocator.rawValue,
                    certPath, keyPathPointer)
        })  != AWS_OP_SUCCESS {
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
        }
    }
    #endif

    #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
    public init(clientWithMtlsPkcs12Path path: String,
                password: String,
                allocator: Allocator = defaultAllocator) throws {
        self.allocator = allocator
        self.rawValue = allocator.allocate(capacity: 1)
        if (password.withByteCursorPointer { passwordCursorPointer in
            aws_tls_ctx_options_init_client_mtls_pkcs12_from_path(rawValue,
                    allocator.rawValue,
                    path, passwordCursorPointer)
        }) != AWS_OP_SUCCESS {
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
        }
    }
    #endif

    public func overrideDefaultTrustStore(caPath: String, caFile: String) throws {
        if aws_tls_ctx_options_override_default_trust_store_from_path(rawValue,
                                                                      caPath,
                                                                      caFile) != AWS_OP_SUCCESS {
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
        }
    }

    public func setAlpnList(_ alpnList: String?) throws {
        if let alpnList = alpnList,
           aws_tls_ctx_options_set_alpn_list(rawValue, alpnList) != AWS_OP_SUCCESS {
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
        }
    }

    public func setVerifyPeer(_ verifyPeer: Bool) {
        aws_tls_ctx_options_set_verify_peer(rawValue, verifyPeer)
    }

    deinit {
        aws_tls_ctx_options_clean_up(rawValue)
        allocator.release(rawValue)
    }
}
