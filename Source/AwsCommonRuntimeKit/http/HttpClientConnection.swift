//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCHttp
import AwsCIo
import Foundation

public class HttpClientConnection {
    private let allocator: Allocator
    let rawValue: UnsafeMutablePointer<aws_http_connection>
    /// This will keep the connection manager alive until connection is alive
    let manager: HttpClientConnectionManager

    /// Called by HttpClientConnectionManager
    init(manager: HttpClientConnectionManager,
         connection: UnsafeMutablePointer<aws_http_connection>,
         allocator: Allocator = defaultAllocator) {
        self.manager = manager
        self.allocator = allocator
        self.rawValue = connection
    }

    public var isOpen: Bool {
        return aws_http_connection_is_open(rawValue)
    }

    /// Close the http connection
// TODO: do we need a explicit close function or deinit is enough?
//    public func close() throws
//        try manager.releaseConnection(connection: self)
//        manager = nil
//    }

    /// Creates a new http stream from the `HttpRequestOptions` given.
    /// - Parameter requestOptions: An `HttpRequestOptions` struct containing callbacks on
    /// the different events from the stream
    /// - Returns: An `HttpStream` containing the `HttpClientConnection`
    public func makeRequest(requestOptions: HttpRequestOptions) throws -> HttpStream {
        var options = aws_http_make_request_options()
        options.self_size = MemoryLayout<aws_http_make_request_options>.size
        options.request = requestOptions.request.rawValue
        options.on_response_body = {_, data, userData -> Int32 in

            guard let userData = userData else {
                return AWS_OP_ERR
            }

            let httpStreamCbData = Unmanaged<HttpStreamCallbackData>.fromOpaque(userData).takeUnretainedValue()

            guard let bufPtr = data?.pointee.ptr,
                  let bufLen = data?.pointee.len,
                  let stream = httpStreamCbData.stream,
                  let incomingBodyFn = httpStreamCbData.requestOptions.onIncomingBody else {
                      return AWS_OP_ERR
                  }

            let callbackBytes = Data(bytesNoCopy: bufPtr, count: bufLen, deallocator: .none)

            incomingBodyFn(stream, callbackBytes)

            return AWS_OP_SUCCESS
        }
        options.on_response_headers = {_, headerBlock, headerArray, headersCount, userData -> Int32 in
            guard let userData = userData else {
                return AWS_OP_ERR
            }

            let httpStreamCbData: HttpStreamCallbackData = Unmanaged<HttpStreamCallbackData>.fromOpaque(userData).takeUnretainedValue()
            var headers = [HttpHeader]()
            for cHeader in UnsafeBufferPointer(start: headerArray, count: headersCount) {
                if let name = cHeader.name.toString(),
                   let value = cHeader.value.toString() {
                    let swiftHeader = HttpHeader(name: name, value: value)
                    headers.append(swiftHeader)
                }

            }
            guard let headersStruct = try? HttpHeaders(fromArray: headers) else {
                return AWS_OP_ERR
            }

            guard let stream = httpStreamCbData.stream else {
                return AWS_OP_ERR
            }
            httpStreamCbData.requestOptions.onIncomingHeaders(stream,
                                                              HttpHeaderBlock(rawValue: headerBlock),
                                                              headersStruct )
            return AWS_OP_SUCCESS
        }

        options.on_response_header_block_done = {_, headerBlock, userData -> Int32 in

            guard let userData = userData else {
                return AWS_OP_ERR
            }
            let httpStreamCbData = Unmanaged<HttpStreamCallbackData>.fromOpaque(userData).takeUnretainedValue()
            guard let stream = httpStreamCbData.stream else {
                return AWS_OP_ERR
            }
            httpStreamCbData.requestOptions.onIncomingHeadersBlockDone(stream, HttpHeaderBlock(rawValue: headerBlock))

            return AWS_OP_SUCCESS
        }
        options.on_complete = {_, errorCode, userData in

            guard let userData = userData else {
                return
            }
            let httpStreamCbData = Unmanaged<HttpStreamCallbackData>.fromOpaque(userData).takeRetainedValue()
            guard let stream = httpStreamCbData.stream,
                  let onStreamCompleteFn = httpStreamCbData.requestOptions.onStreamComplete else {
                      return
                  }
            onStreamCompleteFn(stream, CRTError(errorCode: errorCode))
        }

        let cbData = HttpStreamCallbackData(requestOptions: requestOptions)
        options.user_data = Unmanaged.passRetained(cbData).toOpaque() // Todo: Confirm this logic
        let stream = try HttpStream(httpConnection: self, options: options)
        cbData.stream = stream
        return stream
    }

    deinit {
      try? manager.releaseConnection(connection: self)
    }
}
