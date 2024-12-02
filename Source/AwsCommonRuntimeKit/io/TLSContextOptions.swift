//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import struct Foundation.Data
import AwsCIo
public class TLSContextOptions: CStruct {
    private var rawValue: UnsafeMutablePointer<aws_tls_ctx_options>

    public static func makeDefault() -> TLSContextOptions {
        TLSContextOptions()
    }

    /// Initializes TLSContextOptions for mutual TLS (mTLS), with client certificate and private key in the PKCS#12 format.
    ///
    /// NOTE: This only works on Apple devices. The library is currently only tested on macOS.
    ///
    /// - Parameters:
    ///     - pkcs12Path: Path to PKCS #12 file. The file is loaded from disk and stored internally. It must remain in
    ///     memory for the lifetime of the returned object.
    ///     - password: Password to PKCS #12 file. It must remain in memory for the lifetime of the returned object.
    /// - Throws: CommonRuntimeError.crtError
    public static func makeMTLS(
        pkcs12Path: String,
        password: String) throws -> TLSContextOptions {
        return try TLSContextOptions(mtlsPkcs12FromPath: pkcs12Path, password: password)
    }

    /// Initializes TLSContextOptions for mutual TLS (mTLS), with client certificate and private key. These are in memory
    /// buffers. These buffers must be in the PEM format.
    ///
    /// NOTE: This is unsupported on iOS, tvOS, watchOS.
    ///
    /// - Parameters:
    ///     - certificateData: Certificate contents in memory.
    ///     - privateKeyData: Private key contents in memory.
    /// - Throws: CommonRuntimeError.crtError
    public static func makeMTLS(
        certificateData: Data,
        privateKeyData: Data) throws -> TLSContextOptions {
        #if os(watchOS)
        throw CommonRunTimeError.crtError(CRTError(code: AWS_ERROR_PLATFORM_NOT_SUPPORTED.rawValue))
        #endif
        return try TLSContextOptions(certificateData: certificateData, privateKeyData: privateKeyData)
    }

    /// Initializes TLSContextOptions for mutual TLS (mTLS), with client certificate and private key. These are paths to a
    /// file on disk. These files must be in the PEM format.
    ///
    /// NOTE: This is unsupported on iOS, tvOS, watchOS.
    ///
    /// - Parameters:
    ///     - certificatePath: Path to certificate file.
    ///     - privateKeyPath: Path to private key file.
    /// - Throws: CommonRuntimeError.crtError
    public static func makeMTLS(
        certificatePath: String,
        privateKeyPath: String) throws -> TLSContextOptions {
        #if os(watchOS)
        throw CommonRunTimeError.crtError(CRTError(code: AWS_ERROR_PLATFORM_NOT_SUPPORTED.rawValue))
        #endif
        return try TLSContextOptions(certificatePath: certificatePath, privateKeyPath: privateKeyPath)
    }

    init() {
        self.rawValue = allocator.allocate(capacity: 1)
        aws_tls_ctx_options_init_default_client(rawValue, allocator.rawValue)
    }

    init(mtlsPkcs12FromPath path: String,
         password: String) throws {
        self.rawValue = allocator.allocate(capacity: 1)
        guard password.withByteCursorPointer({ passwordCursorPointer in
            return aws_tls_ctx_options_init_client_mtls_pkcs12_from_path(rawValue,
                                                                         allocator.rawValue,
                                                                         path,
                                                                         passwordCursorPointer)
        }) == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
        }
    }

    init(certificateData: Data,
         privateKeyData: Data) throws {
        self.rawValue = allocator.allocate(capacity: 1)
        guard certificateData.withAWSByteCursorPointer({ certificateByteCursor in
            return privateKeyData.withAWSByteCursorPointer { privatekeyByteCursor in
                return aws_tls_ctx_options_init_client_mtls(self.rawValue,
                                                            allocator.rawValue,
                                                            certificateByteCursor,
                                                            privatekeyByteCursor)
            }})  == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
        }
    }

    init(certificatePath: String, privateKeyPath: String) throws {
            self.rawValue = allocator.allocate(capacity: 1)
            guard aws_tls_ctx_options_init_client_mtls_from_path(self.rawValue,
                                                                 allocator.rawValue,
                                                                 certificatePath,
                                                                 privateKeyPath) == AWS_OP_SUCCESS else {
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
    
    /// Updates TLSContextOptions to use specified options when importing certificate and key into keychain.
    ///
    /// NOTE: This only works on Apple devices using Apple keychain via Secitem.. The library is currently only tested on iOS.
    ///
    /// - Parameters:
    ///     - certLabel: Human readable label to apply to certificate being imported into keychain.
    ///     - keyLabel: Human readable label to apply to key being imported into keychain.
    /// - Throws: CommonRuntimeError.crtError
    public func setSecitemLabels(certLabel: String? = nil, keyLabel: String? = nil) throws {
        let secitemOptions = TLSSecitemOptions(certLabel: certLabel, keyLabel: keyLabel)
        
        if aws_tls_ctx_options_set_secitem_options(rawValue, secitemOptions.rawValue) != AWS_OP_SUCCESS {
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
        }
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
