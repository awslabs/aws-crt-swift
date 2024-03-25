//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo
public class TLSContextOptions: CStruct {
    private var rawValue: UnsafeMutablePointer<aws_tls_ctx_options>

    public static func makeDefault() -> TLSContextOptions {
        TLSContextOptions()
    }

    public static func makeMtlsPkcs12FromPath(
        path: String,
        password: String) throws -> TLSContextOptions {
        try TLSContextOptions(mtlsPkcs12FromPath: path, password: password)
    }

    public static func makeMtlsFromRawData(
        certificateData: String,
        privateKeyData: String) throws -> TLSContextOptions {
        try TLSContextOptions(certificateData: certificateData, privateKeyData: privateKeyData)
    }

    public static func makeMtlsFromFilePath(
        certificatePath: String,
        privateKeyPath: String) throws -> TLSContextOptions {
        try TLSContextOptions(certificatePath: certificatePath, privateKeyPath: privateKeyPath)
    }

    init() {
        self.rawValue = allocator.allocate(capacity: 1)
        aws_tls_ctx_options_init_default_client(rawValue, allocator.rawValue)
    }

    init(mtlsPkcs12FromPath path: String,
         password: String) throws {
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

    init(certificateData cert_data: String,
         privateKeyData private_key_data: String) throws {
        var rawValue: UnsafeMutablePointer<aws_tls_ctx_options>  = allocator.allocate(capacity: 1)
        guard withOptionalByteCursorPointerFromStrings(
            cert_data, private_key_data) { certificateByteCursor, privatekeyByteCursor in
                return aws_tls_ctx_options_init_client_mtls(rawValue,
                                                            allocator.rawValue,
                                                            certificateByteCursor,
                                                            privatekeyByteCursor)
            }  == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
        }
        self.rawValue = rawValue
    }

    init(certificatePath cert_path: String,
         privateKeyPath private_path: String) throws {
        self.rawValue = allocator.allocate(capacity: 1)
        if aws_tls_ctx_options_init_client_mtls_from_path(rawValue,
                                                           allocator.rawValue,
                                                           cert_path,
                                                           private_path) != AWS_OP_SUCCESS {
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

    public func setMinimumTLSVersion(_ tlsVersion: TLSVersion) {
        aws_tls_ctx_options_set_minimum_tls_version(rawValue, aws_tls_versions(rawValue: tlsVersion.rawValue))
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

public enum TLSVersion: UInt32 {
    case SSLv3 = 0
    case TLSv1 = 1
    case TLSv1_1 = 2
    case TLSv1_2 = 3
    case TLSv1_3 = 4
    case systemDefault = 128
}
