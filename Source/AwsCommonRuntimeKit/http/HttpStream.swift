//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp
//TODO: tests?
public class HttpStream {
    var httpStream: UnsafeMutablePointer<aws_http_stream>?

    public let httpConnection: HttpClientConnection

    // Created by HttpClientConnection
    init(httpConnection: HttpClientConnection, options: aws_http_make_request_options) throws {
        self.httpConnection = httpConnection

        httpStream = withUnsafePointer(to: options) { p in aws_http_connection_make_request(httpConnection.rawValue, p)}


        if httpStream == nil {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
    }

    /// Opens the Sliding Read/Write Window by the number of bytes passed as an argument for this HttpStream.
    /// This function should only be called if the user application previously returned less than the length of the
    /// input ByteBuffer from a onIncomingBody() call in a HttpRequestOptions, and should be &lt;= to the total
    /// number of un-acked bytes.
    /// - Parameters:
    ///   - incrementBy:  How many bytes to increment the sliding window by.
    public func updateWindow(incrementBy: Int) {
        //if(httpStream == nil) throw
        aws_http_stream_update_window(httpStream, incrementBy)
    }

    /// Retrieves the Http Response Status Code
    /// - Returns: The status code as `Int32`
    public func statusCode() throws -> Int {
        var status: Int32 = 0
        if aws_http_stream_get_incoming_response_status(httpStream, &status) != AWS_OP_SUCCESS {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        return Int(status)
    }

    ///Activates the client stream.
    public func activate() throws {
        if aws_http_stream_activate(httpStream) != AWS_OP_SUCCESS {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
    }

    deinit {
        //Todo: when the stream is released. Connection is released. Do we need to release it ourself?
        aws_http_stream_release(httpStream)
    }
}
