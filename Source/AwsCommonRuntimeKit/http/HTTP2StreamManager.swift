//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp

/// Manages a Pool of HTTP/2 Streams. Creates and manages HTTP/2 connections under the hood.
public class HTTP2StreamManager {
    let rawValue: UnsafeMutablePointer<aws_http2_stream_manager>

    public init(options: HTTP2StreamManagerOptions) throws {
        let shutdownCallbackCore = ShutdownCallbackCore(options.shutdownCallback)
        let shutdownOptions = shutdownCallbackCore.getRetainedShutdownOptions()
        guard let rawValue: UnsafeMutablePointer<aws_http2_stream_manager> = (
                options.withCPointer(shutdownOptions: shutdownOptions) { managerOptions in
                    aws_http2_stream_manager_new(allocator.rawValue, managerOptions)
                }) else {
            shutdownCallbackCore.release()
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        self.rawValue = rawValue
    }

    /// Acquires an `HTTP2Stream` asynchronously.
    /// There is no need to call activate.
    /// - Parameter requestOptions: The Request to make to the Server.
    /// - Returns: HTTP2Stream when the stream is acquired
    /// - Throws: CommonRunTimeError.crtError
    public func acquireStream(requestOptions: HTTPRequestOptions) async throws -> HTTP2Stream {
        try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<HTTP2Stream, Error>) in
            let httpStreamCallbackCore = HTTPStreamCallbackCore(requestOptions: requestOptions)
            let acquireStreamCore = HTTP2AcquireStreamCore(
                continuation: continuation,
                callbackCore: httpStreamCallbackCore)
            let requestOptions = httpStreamCallbackCore.getRetainedHttpMakeRequestOptions()

            var options = aws_http2_stream_manager_acquire_stream_options()
            options.callback = onStreamAcquired
            options.user_data = acquireStreamCore.passRetained()
            withUnsafePointer(to: requestOptions, { requestOptionsPointer in
                options.options = requestOptionsPointer
                aws_http2_stream_manager_acquire_stream(rawValue, &options)
            })
        })
    }

    deinit {
        aws_http2_stream_manager_release(rawValue)
    }
}

private class HTTP2AcquireStreamCore {
    let continuation: CheckedContinuation<HTTP2Stream, Error>
    let callbackCore: HTTPStreamCallbackCore

    init(continuation: CheckedContinuation<HTTP2Stream, Error>, callbackCore: HTTPStreamCallbackCore) {
        self.callbackCore = callbackCore
        self.continuation = continuation
    }

    func passRetained() -> UnsafeMutableRawPointer {
        Unmanaged.passRetained(self).toOpaque()
    }
}

private func onStreamAcquired(stream: UnsafeMutablePointer<aws_http_stream>?,
                              errorCode: Int32,
                              userData: UnsafeMutableRawPointer!) {
    let acquireStreamCore = Unmanaged<HTTP2AcquireStreamCore>.fromOpaque(userData).takeRetainedValue()
    guard errorCode == AWS_OP_SUCCESS else {
        acquireStreamCore.callbackCore.release()
        acquireStreamCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
        return
    }

    // SUCCESS
    let http2Stream = HTTP2Stream(rawValue: stream!, callbackData: acquireStreamCore.callbackCore)
    acquireStreamCore.continuation.resume(returning: http2Stream)
}
