//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

public class HttpStream {
    internal var httpStream: UnsafeMutablePointer<aws_http_stream>?
    private let httpConnection: HttpClientConnection

    fileprivate init(httpConnection: HttpClientConnection) {
        self.httpConnection = httpConnection
    }

    deinit {
        aws_http_stream_release(httpStream)
    }

    public func getResponseStatusCode() -> Int32 {
        var status: Int32 = 0
        aws_http_stream_get_incoming_response_status(httpStream, &status)
        return status
    }

    public func getConnection() -> HttpClientConnection {
        return httpConnection
    }

    public func updateWindow(incrementBy: Int) {
        aws_http_stream_update_window(httpStream, incrementBy)
    }

    public func activate() {
        aws_http_stream_activate(httpStream)
    }
}