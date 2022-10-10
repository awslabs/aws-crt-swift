//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCHttp
import AwsCIo
import Foundation

public class HttpClientConnection {
    private let allocator: Allocator
    let rawValue: UnsafeMutablePointer<aws_http_connection>
    //Fix: lifetime management issue
    unowned let manager: HttpClientConnectionManager

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
    public func close() throws {
        try manager.releaseConnection(connection: self)
    }

    /// Creates a new http stream from the `HttpRequestOptions` given.
    /// - Parameter requestOptions: An `HttpRequestOptions` struct containing callbacks on
    /// the different events from the stream
    /// - Returns: An `HttpStream` containing the `HttpClientConnection`
    public func makeRequest(requestOptions: HttpRequestOptions) throws -> HttpStream {
        var options = aws_http_make_request_options()
        options.self_size = MemoryLayout<aws_http_make_request_options>.size
        options.request = requestOptions.request.rawValue
        //TODO: where is return value used? change to AWS_OP_SUCCESS and Error
        options.on_response_body = {_, data, userData -> Int32 in

            guard let userData = userData else {
                return -1
            }

            let httpStreamCbData = Unmanaged<HttpStreamCallbackData>.fromOpaque(userData).takeUnretainedValue()

            guard let bufPtr = data?.pointee.ptr,
                  let bufLen = data?.pointee.len,
                  let stream = httpStreamCbData.stream,
                  let incomingBodyFn = httpStreamCbData.requestOptions.onIncomingBody else {
                      return -1
                  }

            //TODO: who deallocates this data?
            let callbackBytes = Data(bytesNoCopy: bufPtr, count: bufLen, deallocator: .none)

            incomingBodyFn(stream, callbackBytes)

            return 0
        }
        options.on_response_headers = {_, headerBlock, headerArray, headersCount, userData -> Int32 in

            guard let userData = userData else {
                return -1
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
            //Todo: fix
            let headersStruct = try! HttpHeaders(fromArray: headers)

            guard let stream = httpStreamCbData.stream else {
                return -1
            }
            httpStreamCbData.requestOptions.onIncomingHeaders(stream,
                                                                      HttpHeaderBlock(rawValue: headerBlock),
                                                                      headersStruct )
            return 0
        }
        options.on_response_header_block_done = {_, headerBlock, userData -> Int32 in

            guard let userData = userData else {
                return -1
            }
            let httpStreamCbData = Unmanaged<HttpStreamCallbackData>.fromOpaque(userData).takeUnretainedValue()
            guard let stream = httpStreamCbData.stream else {
                return -1
            }
            httpStreamCbData.requestOptions.onIncomingHeadersBlockDone(stream, HttpHeaderBlock(rawValue: headerBlock))

            return 0
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
            httpStreamCbData.stream = nil
            onStreamCompleteFn(stream, CRTError(errorCode: errorCode))
        }
//
//        options.on_destroy = { userData in
//            guard let userData = userData else {
//                return
//            }
//            let httpStreamCbData = Unmanaged<HttpStreamCallbackData>.fromOpaque(userData).takeRetainedValue()
//
//            httpStreamCbData.stream = nil
//        }

        let cbData = HttpStreamCallbackData(requestOptions: requestOptions)
        options.user_data = Unmanaged.passRetained(cbData).toOpaque() //Todo: Confirm this logic

        let stream = try HttpStream(httpConnection: self, options: options)
        cbData.stream = stream

        if stream.httpStream == nil {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }

        return stream
    }

    //TODO: discuss two release functions
    deinit {
      try? manager.releaseConnection(connection: self)
       // aws_http_connection_release(rawValue)
    }
}
