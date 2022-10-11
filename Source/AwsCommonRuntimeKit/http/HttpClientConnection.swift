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


    // TODO: I have created an other async function which doesn't give access to HttpStream. So it is easier to manage the lifetime of HttpStream.
    // We might remove makeRequest or makeRequestAsync after discussion/review. For now, keeping both for easier comparison.
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
                return AWS_OP_ERR
            }

            let httpStreamCbData = Unmanaged<HttpStreamCallbackData>.fromOpaque(userData).takeUnretainedValue()

            guard let bufPtr = data?.pointee.ptr,
                  let bufLen = data?.pointee.len,
                  let stream = httpStreamCbData.stream,
                  let incomingBodyFn = httpStreamCbData.requestOptions.onIncomingBody else {
                      return AWS_OP_ERR
                  }

            //TODO: who deallocates this data?
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
            httpStreamCbData.requestOptions.onIncomingHeadersBlockDone(stream, HttpHeaderBlock(rawValue: headerBlock))

            return AWS_OP_SUCCESS
        }
        options.on_complete = {_, errorCode, userData in

            guard let userData = userData else {
                return
            }
            let httpStreamCbData = Unmanaged<HttpStreamCallbackData>.fromOpaque(userData).takeRetainedValue()
            guard let stream = httpStreamCbData.stream else {
                return
            }
            guard let onStreamCompleteFn = httpStreamCbData.requestOptions.onStreamComplete else {
                return
            }
            onStreamCompleteFn(stream, CRTError(errorCode: errorCode))
        }
        let cbData = HttpStreamCallbackData(requestOptions: requestOptions)
        options.user_data = Unmanaged.passRetained(cbData).toOpaque() //Todo: Confirm this logic
        let stream = try HttpStream(httpConnection: self, options: options)
        cbData.stream = stream

        return stream
    }


    /// Sends an HTTP Request Asynchronously and returns Http Code after the on_complete callback has triggered
    /// - Parameter requestOptions: An `HttpRequestOptions` struct containing callbacks on
    /// the different events from the stream
    /// - Returns: An `Http Status Code` if successful
    public func makeRequestAsync(requestOptions: HttpRequestOptions) async throws -> Int {
        try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Int, Error>) in
            makeRequestAsync(requestOptions: requestOptions, continuation: continuation)
        })
    }

    //Todo: This function has a lot of code duplication with makeRequest. Will refactor it if we decide to keep both functions. I like this one better because
    //1. It doesn't exposes HTTPStream. So we can manage it's lifetime ourself.
    //2. User doesn't need extra logic (Semaphore or implementing continuation etc) to wait until on_complete callback has fired.
    private func makeRequestAsync(requestOptions: HttpRequestOptions, continuation: CheckedContinuation<Int, Error>) {
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
            guard let continuation = httpStreamCbData.continuation else {
                return
            }

            guard let stream = httpStreamCbData.stream,
                  let onStreamCompleteFn = httpStreamCbData.requestOptions.onStreamComplete else {
                    continuation.resume(throwing: CommonRunTimeError.crtError(.makeFromLastError()))
                    return
                  }
            onStreamCompleteFn(stream, CRTError(errorCode: errorCode))
            guard let statusCode = try? stream.statusCode() else {
                continuation.resume(throwing: CommonRunTimeError.crtError(.makeFromLastError()))
                return
            }
            continuation.resume(returning: statusCode)

        }

        do {
            let cbData = HttpStreamCallbackData(requestOptions: requestOptions,  continuation: continuation)
            options.user_data = Unmanaged.passRetained(cbData).toOpaque() //Todo: Confirm this logic
            let stream = try HttpStream(httpConnection: self, options: options)
            cbData.stream = stream
            try stream.activate()
        } catch {
            continuation.resume(throwing: CommonRunTimeError.crtError(.makeFromLastError()))
        }
    }

    deinit {
      try? manager.releaseConnection(connection: self)
    }
}
