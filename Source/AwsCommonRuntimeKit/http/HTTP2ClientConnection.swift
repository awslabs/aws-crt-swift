//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCHttp
import AwsCIo
import Foundation

// swiftlint:disable force_try
public class HTTP2ClientConnection: HTTPClientConnection {

    /// Send a SETTINGS frame (HTTP/2 only).
    /// SETTINGS will be applied locally when SETTINGS ACK is received from peer.
    public func updateSetting(setting: HTTP2Settings) async throws {
        try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<(), Error>) in
            let continuationCore = ContinuationCore(continuation: continuation)
            setting.withCStruct { settingList in
                let count = settingList.count
                settingList.withUnsafeBufferPointer { pointer in
                    guard aws_http2_connection_change_settings(
                            rawValue,
                            pointer.baseAddress!,
                            count,
                            onChangeSettingsComplete,
                            continuationCore.passRetained()) == AWS_OP_SUCCESS else {
                        continuation.resume(throwing: CommonRunTimeError.crtError(.makeFromLastError()))
                        return
                    }
                }
            }
        })
    }

}

private func onChangeSettingsComplete(connection: UnsafeMutablePointer<aws_http_connection>?,
                                      errorCode: Int32,
                                      userData: UnsafeMutableRawPointer!) {
    let continuation = Unmanaged<ContinuationCore<()>>.fromOpaque(userData).takeRetainedValue().continuation

    guard errorCode == AWS_OP_SUCCESS else {
        continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
        return
    }

    continuation.resume()
}