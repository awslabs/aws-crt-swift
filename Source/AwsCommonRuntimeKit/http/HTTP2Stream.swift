//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCHttp
import Foundation

// Swift cannot verify the sendability due to a pointer, and thread safety is handled in the C layer.
// So mark it as unchecked Sendable.
/// An HTTP2Stream represents a single HTTP/2 specific HTTP Request/Response.
public class HTTP2Stream: HTTPStream, @unchecked Sendable {
  private let httpConnection: HTTPClientConnection?

  // Called by Connection Manager
  init(
    httpConnection: HTTPClientConnection,
    options: aws_http_make_request_options,
    callbackData: HTTPStreamCallbackCore
  ) throws {
    guard
      let rawValue = withUnsafePointer(
        to: options, { aws_http_connection_make_request(httpConnection.rawValue, $0) })
    else {
      throw CommonRunTimeError.crtError(.makeFromLastError())
    }
    self.httpConnection = httpConnection
    super.init(rawValue: rawValue, callbackData: callbackData)
  }

  // Called by Stream manager
  override init(
    rawValue: UnsafeMutablePointer<aws_http_stream>,
    callbackData: HTTPStreamCallbackCore
  ) {
    httpConnection = nil
    super.init(rawValue: rawValue, callbackData: callbackData)
  }

  /// Reset the HTTP/2 stream (HTTP/2 only).
  /// Note that if the stream closes before this async call is fully processed, the RST_STREAM frame will not be sent.
  /// - Parameter error:  Reason to reset the stream.
  public func resetStream(error: HTTP2Error) throws {
    guard aws_http2_stream_reset(super.rawValue, error.rawValue) == AWS_OP_SUCCESS else {
      throw CommonRunTimeError.crtError(.makeFromLastError())
    }
  }

  /// manualDataWrites must have been enabled during HTTP2Request creation.
  /// A write with that has endOfStream set to be true will end the stream and prevent any further write.
  ///
  /// - Parameters:
  ///   - data: Data to write. It can be empty
  ///   - endOfStream: Set it true to end the stream and prevent any further write.
  ///                  The last frame must be send with the value true.
  /// - Throws: CommonRunTimeError.crtError
  public override func writeChunk(chunk: Data, endOfStream: Bool) async throws {
    var options = aws_http2_stream_write_data_options()
    options.end_stream = endOfStream
    options.on_complete = onWriteComplete
    try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<(), Error>) in
      let continuationCore = ContinuationCore(continuation: continuation)
      let stream = IStreamCore(
        iStreamable: ByteBuffer(data: chunk))
      options.data = stream.rawValue
      options.user_data = continuationCore.passRetained()
      guard
        aws_http2_stream_write_data(
          rawValue,
          &options) == AWS_OP_SUCCESS
      else {
        continuationCore.release()
        continuation.resume(throwing: CommonRunTimeError.crtError(.makeFromLastError()))
        return
      }

    })
  }
}

private func onWriteComplete(
  stream: UnsafeMutablePointer<aws_http_stream>?,
  errorCode: Int32,
  userData: UnsafeMutableRawPointer!
) {
  let continuation = Unmanaged<ContinuationCore<()>>.fromOpaque(userData).takeRetainedValue()
    .continuation
  guard errorCode == AWS_OP_SUCCESS else {
    continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
    return
  }

  // SUCCESS
  continuation.resume()
}
