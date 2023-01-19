//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCHttp
import AwsCCommon
import Foundation

/// Core classes have manual memory management.
/// You have to balance the retain & release calls in all cases to avoid leaking memory.
class HTTPStreamCallbackCore {
    let requestOptions: HTTPRequestOptions

    init(requestOptions: HTTPRequestOptions) {
        self.requestOptions = requestOptions
    }

    private func getRetainedSelf() -> UnsafeMutableRawPointer {
        return Unmanaged.passRetained(self).toOpaque()
    }

    /// This function does a manual retain on HTTPStreamCallbackDataCore
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
        options.http2_use_manual_data_writes = requestOptions.http2ManualDataWrites
        return options
    }

    /// Manually release the reference If you fail to create something that uses the HTTPStreamCallbackDataCore
    func release() {
        Unmanaged.passUnretained(self).release()
    }
}

private func onResponseHeaders(stream: UnsafeMutablePointer<aws_http_stream>?,
                               headerBlock: aws_http_header_block,
                               headerArray: UnsafePointer<aws_http_header>?,
                               headersCount: Int,
                               userData: UnsafeMutableRawPointer!) -> Int32 {
    let httpStreamCbData = Unmanaged<HTTPStreamCallbackCore>
        .fromOpaque(userData)
        .takeUnretainedValue()
    let headers = UnsafeBufferPointer(
        start: headerArray,
        count: headersCount).map { HTTPHeader(rawValue: $0) }
    var status: Int32 = 0
    guard aws_http_stream_get_incoming_response_status(stream!, &status) == AWS_OP_SUCCESS else {
        fatalError(
            """
            Failed to get HTTP status code in onResponseHeaders callback with error
            \(CommonRunTimeError.crtError(.makeFromLastError()))
            """
        )
    }
    httpStreamCbData.requestOptions.onIncomingHeaders(status,
                                                      HTTPHeaderBlock(rawValue: headerBlock),
                                                      headers)
    return AWS_OP_SUCCESS
}

private func onResponseHeaderBlockDone(stream: UnsafeMutablePointer<aws_http_stream>?,
                                       headerBlock: aws_http_header_block,
                                       userData: UnsafeMutableRawPointer!) -> Int32 {
    let httpStreamCbData = Unmanaged<HTTPStreamCallbackCore>.fromOpaque(userData).takeUnretainedValue()
    httpStreamCbData.requestOptions.onIncomingHeadersBlockDone(HTTPHeaderBlock(rawValue: headerBlock))
    return AWS_OP_SUCCESS
}

private func onResponseBody(stream: UnsafeMutablePointer<aws_http_stream>?,
                            data: UnsafePointer<aws_byte_cursor>?,
                            userData: UnsafeMutableRawPointer!) -> Int32 {
    let httpStreamCbData = Unmanaged<HTTPStreamCallbackCore>.fromOpaque(userData).takeUnretainedValue()
    guard let bufPtr = data?.pointee.ptr,
          let bufLen = data?.pointee.len else {
        return AWS_OP_ERR
    }

    let incomingBodyFn = httpStreamCbData.requestOptions.onIncomingBody
    let callbackBytes = Data(bytesNoCopy: bufPtr, count: bufLen, deallocator: .none)
    incomingBodyFn(callbackBytes)
    return AWS_OP_SUCCESS
}

private func onComplete(stream: UnsafeMutablePointer<aws_http_stream>?,
                        errorCode: Int32,
                        userData: UnsafeMutableRawPointer!) {

    let httpStreamCbData = Unmanaged<HTTPStreamCallbackCore>.fromOpaque(userData).takeUnretainedValue()
    let onStreamCompleteFn = httpStreamCbData.requestOptions.onStreamComplete
    guard errorCode == AWS_OP_SUCCESS else {
        onStreamCompleteFn(.failure(CommonRunTimeError.crtError(CRTError(code: errorCode))))
        return
    }

    var status: Int32 = 0
    guard aws_http_stream_get_incoming_response_status(stream!, &status) == AWS_OP_SUCCESS else {
        fatalError(
            """
            Failed to get HTTP status code in onComplete callback with error
            \(CommonRunTimeError.crtError(.makeFromLastError()))
            """
        )
    }
    onStreamCompleteFn(.success(status))
}

private func onDestroy(userData: UnsafeMutableRawPointer!) {
    Unmanaged<HTTPStreamCallbackCore>.fromOpaque(userData).release()
}
