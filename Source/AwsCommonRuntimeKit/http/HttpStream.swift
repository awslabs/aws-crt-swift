//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp

public actor HttpStream {
    nonisolated let rawValue: UnsafeMutablePointer<aws_http_stream>
    var callbackData: HttpStreamCallbackCore
    private var activated: Bool = false

    // Called by HttpClientConnection
    init(httpConnection: HttpClientConnection, options: aws_http_make_request_options, callbackData: HttpStreamCallbackCore) throws {
        self.callbackData = callbackData
        guard let rawValue = withUnsafePointer(to: options, { aws_http_connection_make_request(httpConnection.rawValue, $0) }) else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        self.rawValue = rawValue
    }

    /// Opens the Sliding Read/Write Window by the number of bytes passed as an argument for this HttpStream.
    /// This function should only be called if the user application previously returned less than the length of the
    /// input ByteBuffer from a onIncomingBody() call in a HttpRequestOptions, and should be &lt;= to the total
    /// number of un-acked bytes.
    /// - Parameters:
    ///   - incrementBy:  How many bytes to increment the sliding window by.
    public nonisolated func updateWindow(incrementBy: Int) {
        aws_http_stream_update_window(rawValue, incrementBy)
    }

    /// Retrieves the Http Response Status Code
    /// - Returns: The status code as `Int32`
    public nonisolated func statusCode() throws -> Int {
        var status: Int32 = 0
        if aws_http_stream_get_incoming_response_status(rawValue, &status) != AWS_OP_SUCCESS {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        return Int(status)
    }

    /// Activates the client stream.
    /// Multiple calls to activate have no effect if the stream is already activated
    /// This is thread safe because HttpStream is an actor
    public func activate() throws {
        if !activated {
            activated = true
            callbackData.stream = self
            if aws_http_stream_activate(rawValue) != AWS_OP_SUCCESS {
                activated = false
                callbackData.stream = nil
                throw CommonRunTimeError.crtError(.makeFromLastError())
            }
        }
    }

    deinit {
        aws_http_stream_release(rawValue)
    }
}
