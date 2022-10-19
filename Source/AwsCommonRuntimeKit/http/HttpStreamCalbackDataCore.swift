//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCHttp
import AwsCCommon
import Foundation

/// Core classes have manual memory management.
/// You have to balance the retain & release calls in all cases to avoid leaking memory.
class HttpStreamCallbackDataCore {
    let requestOptions: HttpRequestOptions
    var stream: HttpStream?

    init(requestOptions: HttpRequestOptions) {
        self.requestOptions = requestOptions
    }

    /// This function does a manual retain on HttpStreamCallbackDataCore
    /// to keep it until until on_destroy callback has fired which will do the release.
    func getRetainedHttpMakeRequestOptions() -> aws_http_make_request_options {
        var options = aws_http_make_request_options()
        options.self_size = MemoryLayout<aws_http_make_request_options>.size
        options.request = requestOptions.request.rawValue
        options.on_response_body = onResponseBody
        options.on_response_headers = onResponseHeaders
        options.on_response_header_block_done = onResponseHeaderBlockDone
        options.on_complete = onComplete
        options.on_destroy = onDestroy
        options.user_data = Unmanaged.passRetained(self).toOpaque()
        return options
    }

}
func onResponseBody(stream: UnsafeMutablePointer<aws_http_stream>?,
                    data: UnsafePointer<aws_byte_cursor>?,
                    userData: UnsafeMutableRawPointer?) -> Int32 {
    guard let userData = userData else {
        return AWS_OP_ERR
    }

    let httpStreamCbData = Unmanaged<HttpStreamCallbackDataCore>.fromOpaque(userData).takeUnretainedValue()

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

// TODO: Maybe update to fire three headers callback (informational, main, and trailing) only once
func onResponseHeaders(stream: UnsafeMutablePointer<aws_http_stream>?,
                       headerBlock: aws_http_header_block,
                       headerArray: UnsafePointer<aws_http_header>?,
                       headersCount: Int,
                       userData: UnsafeMutableRawPointer?) -> Int32 {

    guard let userData = userData else {
        return AWS_OP_ERR
    }

    let httpStreamCbData: HttpStreamCallbackDataCore = Unmanaged<HttpStreamCallbackDataCore>.fromOpaque(userData).takeUnretainedValue()
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

func onResponseHeaderBlockDone(stream: UnsafeMutablePointer<aws_http_stream>?,
                               headerBlock: aws_http_header_block,
                               userData: UnsafeMutableRawPointer?) -> Int32 {
    guard let userData = userData else {
        return AWS_OP_ERR
    }
    let httpStreamCbData = Unmanaged<HttpStreamCallbackDataCore>.fromOpaque(userData).takeUnretainedValue()
    guard let stream = httpStreamCbData.stream else {
        return AWS_OP_ERR
    }
    httpStreamCbData.requestOptions.onIncomingHeadersBlockDone(stream, HttpHeaderBlock(rawValue: headerBlock))
    return AWS_OP_SUCCESS
}

func onComplete(stream: UnsafeMutablePointer<aws_http_stream>?,
                errorCode: Int32,
                userData: UnsafeMutableRawPointer?) {
    guard let userData = userData else {
        return
    }
    let httpStreamCbData = Unmanaged<HttpStreamCallbackDataCore>.fromOpaque(userData).takeUnretainedValue()
    guard let stream = httpStreamCbData.stream,
          let onStreamCompleteFn = httpStreamCbData.requestOptions.onStreamComplete else {
        return
    }
    onStreamCompleteFn(stream, CRTError(errorCode: errorCode))
    httpStreamCbData.stream = nil
}

func onDestroy(userData: UnsafeMutableRawPointer?) {
    guard let userData = userData else {
        return
    }
    Unmanaged<HttpStreamCallbackDataCore>.fromOpaque(userData).release()
}
