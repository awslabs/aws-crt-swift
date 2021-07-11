//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp

public class HttpStream {
    var httpStream: UnsafeMutablePointer<aws_http_stream>?
    
    public let httpConnection: HttpClientConnection
    
    /// Retrieves the Http Response Status Code
    /// - Returns: The status code as `Int32`
    public var statusCode: Int32 {
        var status: Int32 = 0
        aws_http_stream_get_incoming_response_status(httpStream, &status)
        return status
    }
    
    init(httpConnection: HttpClientConnection) {
        self.httpConnection = httpConnection
    }
    
    /// Opens the Sliding Read/Write Window by the number of bytes passed as an argument for this HttpStream.
    /// This function should only be called if the user application previously returned less than the length of the
    /// input ByteBuffer from a onIncomingBody() call in a HttpRequestOptions, and should be &lt;= to the total
    /// number of un-acked bytes.
    /// - Parameters:
    ///   - incrementBy:  How many bytes to increment the sliding window by.
    public func updateWindow(incrementBy: Int) {
        aws_http_stream_update_window(httpStream, incrementBy)
    }
    
    ///Activates the client stream.
    public func activate() {
        aws_http_stream_activate(httpStream)
    }
    
    deinit {
        aws_http_stream_release(httpStream)
    }
}
