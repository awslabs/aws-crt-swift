//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCHttp
import AwsCIo
import Foundation

public class HTTP2ClientConnection: HTTPClientConnection {

    /// Creates a new http2 stream from the `HTTPRequestOptions` given.
    /// - Parameter requestOptions: An `HTTPRequestOptions` struct containing callbacks on
    /// the different events from the stream
    /// - Returns: An `HTTP2Stream`
    override public func makeRequest(requestOptions: HTTPRequestOptions) throws -> HTTPStream {
        let httpStreamCallbackCore = HTTPStreamCallbackCore(requestOptions: requestOptions)
        do {
            return try HTTP2Stream(httpConnection: self,
                                   options: httpStreamCallbackCore.getRetainedHttpMakeRequestOptions(),
                                   callbackData: httpStreamCallbackCore)
        } catch {
            httpStreamCallbackCore.release()
            throw error
        }
    }

    /// Send a SETTINGS frame (HTTP/2 only).
    /// SETTINGS will be applied locally when settings ACK is received from peer.
    /// - Parameter setting: The settings to change
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
                        continuationCore.release()
                        continuation.resume(throwing: CommonRunTimeError.crtError(.makeFromLastError()))
                        return
                    }
                }
            }
        })
    }

    /// Send a PING frame. Round-trip-time is calculated when PING ACK is received from peer.
    /// - Parameter data: (Optional) 8 Bytes data with the PING frame. Data count must be exact 8 bytes.
    /// - Returns: The round trip time in nano seconds for the connection.
    public func sendPing(data: Data = Data()) async throws -> UInt64 {
        try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<UInt64, Error>) in
            let continuationCore = ContinuationCore(continuation: continuation)
            data.withAWSByteCursorPointer { dataPointer in
                guard aws_http2_connection_ping(
                        rawValue,
                        data.isEmpty ? nil : dataPointer,
                        onPingComplete,
                        continuationCore.passRetained()) == AWS_OP_SUCCESS
                else {
                    continuationCore.release()
                    continuation.resume(throwing: CommonRunTimeError.crtError(.makeFromLastError()))
                    return
                }
            }
        })
    }

    /// Send a custom GOAWAY frame.
    ///
    /// Note that the connection automatically attempts to send a GOAWAY during
    /// shutdown (unless a GOAWAY with a valid Last-Stream-ID has already been sent).
    ///
    /// This call can be used to gracefully warn the peer of an impending shutdown
    /// (error=0, allowMoreStreams=true), or to customize the final GOAWAY
    /// frame that is sent by this connection.
    ///
    /// The other end may not receive the goaway, if the connection already closed.
    ///
    /// - Parameters:
    ///   - error: The HTTP/2 error code to send.
    ///   - allowMoreStreams: If true, new peer-initiated streams will continue to be acknowledged and the GOAWAY's Last-Stream-ID will
    ///                       be set to a max value. If false, new peer-initiated streams will be ignored and the GOAWAY's
    ///                       Last-Stream-ID will be set to the latest acknowledged stream.
    ///   - debugData: (Optional) debug data to send. Size must not exceed 16KB.
    public func sendGoAway(error: HTTP2Error, allowMoreStreams: Bool, debugData: Data = Data()) {
        debugData.withAWSByteCursorPointer { dataPointer in
            aws_http2_connection_send_goaway(
                rawValue,
                error.rawValue,
                allowMoreStreams,
                dataPointer)
        }
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

    // SUCCESS
    continuation.resume()
}

private func onPingComplete(connection: UnsafeMutablePointer<aws_http_connection>?,
                            roundTripTimeNs: UInt64,
                            errorCode: Int32,
                            userData: UnsafeMutableRawPointer!) {
    let continuation = Unmanaged<ContinuationCore<UInt64>>.fromOpaque(userData).takeRetainedValue().continuation

    guard errorCode == AWS_OP_SUCCESS else {
        continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
        return
    }

    // SUCCESS
    continuation.resume(returning: roundTripTimeNs)
}
