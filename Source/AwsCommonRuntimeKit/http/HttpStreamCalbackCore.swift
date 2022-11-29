//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCHttp
import AwsCCommon
import Foundation

/// Core classes have manual memory management.
/// You have to balance the retain & release calls in all cases to avoid leaking memory.
class HttpStreamCallbackCore {
    let requestOptions: HttpRequestOptions
    var stream: HttpStream?

    init(requestOptions: HttpRequestOptions) {
        self.requestOptions = requestOptions
    }

    private func getRetainedSelf() -> UnsafeMutableRawPointer {
        return Unmanaged.passRetained(self).toOpaque()
    }

    /// This function does a manual retain on HttpStreamCallbackDataCore
    /// to keep it until until on_destroy callback has fired which will do the release.
    /// If you fail to create something that uses the aws_http_make_request_options,
    /// you must call release() to avoid leaking memory.
    func getRetainedHttpMakeRequestOptions() -> aws_http_make_request_options {
        var options = aws_http_make_request_options()
        options.self_size = MemoryLayout<aws_http_make_request_options>.size
        options.request = requestOptions.request.rawValue
        options.on_response_body = onResponseBody
        options.on_response_headers = onResponseHeaders
        options.on_response_header_block_done = onResponseHeaderBlockDone
        options.on_complete = onComplete
        options.on_destroy = onDestroy
        options.user_data = getRetainedSelf()
        return options
    }

    /// Manually release the reference If you fail to create something that uses the HttpStreamCallbackDataCore
    func release() {
        Unmanaged.passUnretained(self).release()
    }
}

// TODO: Maybe update to fire three headers callback (informational, main, and trailing) only once
private func onResponseHeaders(stream: UnsafeMutablePointer<aws_http_stream>?,
                               headerBlock: aws_http_header_block,
                               headerArray: UnsafePointer<aws_http_header>?,
                               headersCount: Int,
                               userData: UnsafeMutableRawPointer!) -> Int32 {
    let httpStreamCbData: HttpStreamCallbackCore = Unmanaged<HttpStreamCallbackCore>.fromOpaque(userData).takeUnretainedValue()
    var headers = [HttpHeader]()

    for cHeader in UnsafeBufferPointer(start: headerArray, count: headersCount) {
        let name = cHeader.name.toString()
        let value = cHeader.value.toString()
        headers.append(HttpHeader(name: name, value: value))
    }

    guard let headersStruct = try? HttpHeaders(fromArray: headers) else {
        return AWS_OP_ERR
    }

    let stream = httpStreamCbData.stream!
    httpStreamCbData.requestOptions.onIncomingHeaders(stream,
            HttpHeaderBlock(rawValue: headerBlock),
            headersStruct )
    return AWS_OP_SUCCESS
}

private func onResponseHeaderBlockDone(stream: UnsafeMutablePointer<aws_http_stream>?,
                                       headerBlock: aws_http_header_block,
                                       userData: UnsafeMutableRawPointer!) -> Int32 {
    let httpStreamCbData = Unmanaged<HttpStreamCallbackCore>.fromOpaque(userData).takeUnretainedValue()
    let stream = httpStreamCbData.stream!

    httpStreamCbData.requestOptions.onIncomingHeadersBlockDone(stream, HttpHeaderBlock(rawValue: headerBlock))
    return AWS_OP_SUCCESS
}

private func onResponseBody(stream: UnsafeMutablePointer<aws_http_stream>?,
                            data: UnsafePointer<aws_byte_cursor>?,
                            userData: UnsafeMutableRawPointer!) -> Int32 {
    let httpStreamCbData = Unmanaged<HttpStreamCallbackCore>.fromOpaque(userData).takeUnretainedValue()
    guard let bufPtr = data?.pointee.ptr,
          let bufLen = data?.pointee.len else {
        return AWS_OP_ERR
    }

    let incomingBodyFn = httpStreamCbData.requestOptions.onIncomingBody
    let callbackBytes = Data(bytesNoCopy: bufPtr, count: bufLen, deallocator: .none)
    incomingBodyFn((httpStreamCbData.stream)!, callbackBytes)
    return AWS_OP_SUCCESS
}

private func onComplete(stream: UnsafeMutablePointer<aws_http_stream>?,
                        errorCode: Int32,
                        userData: UnsafeMutableRawPointer!) {

    let httpStreamCbData = Unmanaged<HttpStreamCallbackCore>.fromOpaque(userData).takeUnretainedValue()
    let stream = httpStreamCbData.stream!
    let onStreamCompleteFn = httpStreamCbData.requestOptions.onStreamComplete
    let crtError = errorCode == AWS_OP_SUCCESS ? nil : CRTError(code: errorCode)
    onStreamCompleteFn(stream, crtError)
    httpStreamCbData.stream = nil
}

private func onDestroy(userData: UnsafeMutableRawPointer!) {
    Unmanaged<HttpStreamCallbackCore>.fromOpaque(userData).release()
}
