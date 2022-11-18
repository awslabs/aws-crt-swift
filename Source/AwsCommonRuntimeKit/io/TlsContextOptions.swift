//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo
public class TlsContextOptions: CStruct {
    private let allocator: Allocator
    private var rawValue: UnsafeMutablePointer<aws_tls_ctx_options>

    public static func makeDefault(allocator: Allocator = defaultAllocator) -> TlsContextOptions {
        TlsContextOptions(allocator: allocator)
    }

    public static func makeMtlsPkcs12FromPath(path: String, password: String, allocator: Allocator = defaultAllocator) throws -> TlsContextOptions {
        try TlsContextOptions(mtlsPkcs12FromPath: path, password: password, allocator: allocator)
    }

    init(allocator: Allocator) {
        self.allocator = allocator
        self.rawValue = allocator.allocate(capacity: 1)
        aws_tls_ctx_options_init_default_client(rawValue, allocator.rawValue)
    }

    init(mtlsPkcs12FromPath path: String,
         password: String,
         allocator: Allocator) throws {
        self.allocator = allocator
        self.rawValue = allocator.allocate(capacity: 1)
        if (password.withByteCursorPointer { passwordCursorPointer in
            aws_tls_ctx_options_init_client_mtls_pkcs12_from_path(rawValue,
                                                                  allocator.rawValue,
                                                                  path,
                                                                  passwordCursorPointer)
        }) != AWS_OP_SUCCESS {
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
        }
    }

    public static func isAlpnSupported() -> Bool {
        return aws_tls_is_alpn_available()
    }

    public func overrideDefaultTrustStore(caPath: String, caFile: String) throws {
        if aws_tls_ctx_options_override_default_trust_store_from_path(rawValue,
                                                                      caPath,
                                                                      caFile) != AWS_OP_SUCCESS {
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
        }
    }

    public func setAlpnList(_ alpnList: [String]) {
        aws_tls_ctx_options_set_alpn_list(rawValue, alpnList.joined(separator: ";"))
    }

    public func setVerifyPeer(_ verifyPeer: Bool) {
        aws_tls_ctx_options_set_verify_peer(rawValue, verifyPeer)
    }

    typealias RawType = aws_tls_ctx_options
    func withCStruct<Result>(_ body: (aws_tls_ctx_options) -> Result) -> Result {
        return body(rawValue.pointee)
    }

    deinit {
        aws_tls_ctx_options_clean_up(rawValue)
        allocator.release(rawValue)
    }
}
