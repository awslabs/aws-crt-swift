//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp
import Foundation

/// An HTTP1Stream represents a single HTTP/1.1 specific Http Request/Response.
public class HTTP1Stream: HTTPStream {
    /// Stream keeps a reference to HttpConnection to keep it alive
    private let httpConnection: HTTPClientConnection

    // Called by HTTPClientConnection
    init(
        httpConnection: HTTPClientConnection,
        options: aws_http_make_request_options,
        callbackData: HTTPStreamCallbackCore) throws {
        guard let rawValue = withUnsafePointer(
                to: options, { aws_http_connection_make_request(httpConnection.rawValue, $0) }) else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        self.httpConnection = httpConnection
        super.init(rawValue: rawValue, callbackData: callbackData)
    }

    /// Submit a chunk of data to be sent on an HTTP/1.1 stream.
    /// The stream must have specified "chunked" in a "transfer-encoding" header and no body.
    /// activate() must be called before any chunks are submitted.
    /// A final chunk with size 0 must be submitted to successfully complete the HTTP-stream.
    /// - Parameters:
    ///     - chunk: Chunk to write
    /// - Throws:
    public override func writeChunk(chunk: Data) async throws {
        var options = aws_http1_chunk_options()
        options.on_complete = onWriteComplete
        try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<(), Error>) in
            let continuationCore = ContinuationCore(continuation: continuation)
            let stream = IStreamCore(
                iStreamable: ByteBuffer(data: chunk))
            options.chunk_data = stream.rawValue
            options.chunk_data_size = UInt64(chunk.count)
            options.user_data = continuationCore.passRetained()
            guard aws_http1_stream_write_chunk(
                    rawValue,
                    &options) == AWS_OP_SUCCESS else {
                continuationCore.release()
                continuation.resume(throwing: CommonRunTimeError.crtError(.makeFromLastError()))
                return
            }

        })
    }

}


private func onWriteComplete(stream: UnsafeMutablePointer<aws_http_stream>?,
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

