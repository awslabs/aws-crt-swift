//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCHttp
import Foundation
import AwsCIo

public class HttpClientConnection {
    private let allocator : Allocator
    private let rawValue: UnsafeMutablePointer<aws_http_connection>

    fileprivate init(connection: UnsafeMutablePointer<aws_http_connection>, allocator: Allocator = defaultAllocator) {
        self.allocator = allocator
        self.rawValue = connection
    }

    deinit {
        aws_http_connection_release(rawValue)
    }

    public static func createConnection(options: inout HttpClientConnectionOptions, allocator: Allocator = defaultAllocator) {
        let tempHostName = options.hostName.newByteCursor()

        var unmanagedConnectionOptions = aws_http_client_connection_options(
                self_size: 0,
                allocator: allocator.rawValue,
                bootstrap: options.clientBootstrap.rawValue,
                host_name: tempHostName.rawValue,
                port: options.port,
                socket_options: UnsafePointer(&options.socketOptions.rawValue),
                tls_options: nil,
                proxy_options: nil,
                monitoring_options: nil,
                initial_window_size: options.initialWindowSize,
                user_data: nil,
                on_setup: onClientConnectionSetup,
                on_shutdown: onClientConnectionShutdown,
                manual_window_management: false,
                http2_options: nil
        )

        unmanagedConnectionOptions.self_size = MemoryLayout.size(ofValue: unmanagedConnectionOptions)

        if let tlsOptions = options.tlsOptions {
            unmanagedConnectionOptions.tls_options = UnsafePointer(&tlsOptions.rawValue)
        }

        //come back to this,
//        if let proxyOptions = options.proxyOptions {
//            unmanagedConnectionOptions.proxy_options = UnsafePointer(&proxyOptions.rawValue)
//        }

        let callbackData = HttpClientConnectionCallbackData(options: options, allocator: allocator)
        unmanagedConnectionOptions.user_data = Unmanaged.passRetained(callbackData).toOpaque()

        aws_http_client_connect(&unmanagedConnectionOptions)
    }

    public var isOpen: Bool {
       return aws_http_connection_is_open(self.rawValue);
    }

    public func close() {
        return aws_http_connection_close(self.rawValue);
    }
    


    public func newClientStream(requestOptions: HttpRequestOptions) -> HttpStream {
        var options = aws_http_make_request_options()
        options.self_size = MemoryLayout<aws_http_make_request_options>.size
        options.request = requestOptions.request.rawValue
        options.on_response_body = onIncomingBody
        options.on_response_headers = onIncomingHeaders
        options.on_response_header_block_done = onIncomingHeadersBlockDone
        options.on_complete = onStreamCompleted

        let cbData = HttpStreamCallbackData(requestOptions: requestOptions)
        options.user_data = Unmanaged.passRetained(cbData).toOpaque()

        let stream = HttpStream(httpConnection: self)
        cbData.stream = stream
        stream.httpStream = aws_http_connection_make_request(self.rawValue, &options)

        return stream
    }
    
}

private func onIncomingHeaders(_ stream: UnsafeMutablePointer<aws_http_stream>?,  _ headerBlock: aws_http_header_block, _ headerArray: UnsafePointer<aws_http_header>?, _ headersCount: Int,  _ userData: UnsafeMutableRawPointer!) -> Int32 {
    let httpStreamCbData: HttpStreamCallbackData = Unmanaged.fromOpaque(userData).takeUnretainedValue()
    var headers: [HttpHeader] = []

    for header in UnsafeBufferPointer(start: headerArray, count: headersCount) {
        headers.append(header)
    }
    httpStreamCbData.requestOptions.onIncomingHeaders(httpStreamCbData.stream!, headerBlock.headerBlock, headers)
    return 0
}

private func onIncomingHeadersBlockDone(_ stream: UnsafeMutablePointer<aws_http_stream>?, _ headerBlock: aws_http_header_block, _ userData: UnsafeMutableRawPointer!) -> Int32 {
    let httpStreamCbData: HttpStreamCallbackData = Unmanaged.fromOpaque(userData).takeUnretainedValue()
    httpStreamCbData.requestOptions.onIncomingHeadersBlockDone(httpStreamCbData.stream!, headerBlock.headerBlock)
    return 0
}

private func onIncomingBody(_ stream: UnsafeMutablePointer<aws_http_stream>?, _ data: UnsafePointer<aws_byte_cursor>?, _ userData: UnsafeMutableRawPointer!) -> Int32 {
    let httpStreamCbData: HttpStreamCallbackData = Unmanaged.fromOpaque(userData).takeUnretainedValue()
    guard let bufPtr = data!.pointee.ptr else {
        return -1
    }
    guard let bufLen = data?.pointee.len else {
        return -1
    }

    let callbackBytes = Data(bytesNoCopy: bufPtr, count: bufLen, deallocator: .none)
    httpStreamCbData.requestOptions.onIncomingBody!(httpStreamCbData.stream!, callbackBytes)

    return 0
}

private func onStreamCompleted(_ stream: UnsafeMutablePointer<aws_http_stream>?, _ errorCode: Int32, _ userData: UnsafeMutableRawPointer!) {
    let httpStreamCbData: HttpStreamCallbackData = Unmanaged.fromOpaque(userData).takeRetainedValue()
    httpStreamCbData.requestOptions.onStreamComplete!(httpStreamCbData.stream!, errorCode)
}

private func onClientConnectionSetup(_ unmanagedConnection: UnsafeMutablePointer<aws_http_connection>!, _ errorCode: Int32, _ userData: UnsafeMutableRawPointer!) {
        if (unmanagedConnection != nil && errorCode == 0) {
            let callbackData: HttpClientConnectionCallbackData = Unmanaged.fromOpaque(userData).takeUnretainedValue()
            callbackData.managedConnection = HttpClientConnection(connection: unmanagedConnection, allocator: callbackData.allocator)
            callbackData.connectionOptions.onConnectionSetup(callbackData.managedConnection, errorCode)
        } else {
            let callbackData: HttpClientConnectionCallbackData = Unmanaged.fromOpaque(userData).takeRetainedValue()
            callbackData.connectionOptions.onConnectionSetup(nil, errorCode)
        }
    }

private func onClientConnectionShutdown(_ unmanagedConnection: UnsafeMutablePointer<aws_http_connection>?, _ errorCode: Int32, _ userData: UnsafeMutableRawPointer!) {
    let callbackData: HttpClientConnectionCallbackData = Unmanaged.fromOpaque(userData).takeRetainedValue()

    callbackData.connectionOptions.onConnectionShutdown(callbackData.managedConnection, errorCode)
}
