//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp
import Foundation

/// An base abstract class that represents a single Http Request/Response for both HTTP/1.1 and HTTP/2.
/// Can be used to update the Window size, and get status code.
public class HTTPStream: @unchecked Sendable {
    let rawValue: UnsafeMutablePointer<aws_http_stream>
    var callbackData: HTTPStreamCallbackCore

    init(rawValue: UnsafeMutablePointer<aws_http_stream>,
         callbackData: HTTPStreamCallbackCore) {
        self.callbackData = callbackData
        self.rawValue = rawValue
    }

    /// Opens the Sliding Read/Write Window by the number of bytes passed as an argument for this HTTPStream.
    /// This function should only be called if the user application previously returned less than the length of the
    /// input ByteBuffer from a onIncomingBody() call in a HTTPRequestOptions, and should be &lt;= to the total
    /// number of un-acked bytes.
    /// - Parameters:
    ///   - incrementBy:  How many bytes to increment the sliding window by.
    public func updateWindow(incrementBy: Int) {
        aws_http_stream_update_window(rawValue, incrementBy)
    }

    /// Retrieves the Http Response Status Code
    /// - Returns: The status code as `Int32`
    public func statusCode() throws -> Int {
        var status: Int32 = 0
        if aws_http_stream_get_incoming_response_status(rawValue, &status) != AWS_OP_SUCCESS {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        return Int(status)
    }

    /// Activates the client stream.
    public func activate() throws {
        if aws_http_stream_activate(rawValue) != AWS_OP_SUCCESS {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
    }
    
    /// This method must be overridden in each subclass because this function is specific to each subclass.
    /// For HTTP/1.1 see ``HTTP1Stream/writeChunk(chunk:endOfStream:)``
    /// For HTTP2: see  ``HTTP2Stream/writeChunk(chunk:endOfStream:)``
    public func writeChunk(chunk: Data, endOfStream: Bool) async throws {
        fatalError("writeChunk is not implemented for HTTPStream base")
    }
    
    deinit {
        aws_http_stream_release(rawValue)
    }
}
