//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import Foundation

public struct HTTPRequestOptions {
    public typealias OnIncomingHeaders = (_ statusCode: Int32,
                                          _ headerBlock: HTTPHeaderBlock,
                                          _ headers: [HTTPHeader]) -> Void
    public typealias OnIncomingHeadersBlockDone = (_ headerBlock: HTTPHeaderBlock) -> Void
    public typealias OnIncomingBody = (_ bodyChunk: Data) -> Void
    public typealias OnStreamComplete = (_ result: Result<Int32, CommonRunTimeError>) -> Void

    /// Outgoing request.
    let request: HTTPRequestBase

    /// Invoked repeatedly as headers are received.
    public let onIncomingHeaders: OnIncomingHeaders

    /// Invoked when response header block has been completely read.
    public let onIncomingHeadersBlockDone: OnIncomingHeadersBlockDone

    /// Invoked repeatedly as body data is received.
    public let onIncomingBody: OnIncomingBody

    /// Invoked when request/response stream is complete, whether successful or unsuccessful
    public let onStreamComplete: OnStreamComplete

    /// When using HTTP/2, set http2ManualDataWrites to true to specify that request body data will be provided over time.
    /// The stream will only be polled for writing when data has been supplied via `HTTP2Stream.writeData`
    public var http2ManualDataWrites: Bool = false

    public init(request: HTTPRequestBase,
                onIncomingHeaders: @escaping OnIncomingHeaders,
                onIncomingHeadersBlockDone: @escaping OnIncomingHeadersBlockDone,
                onIncomingBody: @escaping OnIncomingBody,
                onStreamComplete: @escaping OnStreamComplete,
                http2ManualDataWrites: Bool = false) {
        self.request = request
        self.onIncomingHeaders = onIncomingHeaders
        self.onIncomingHeadersBlockDone = onIncomingHeadersBlockDone
        self.onIncomingBody = onIncomingBody
        self.onStreamComplete = onStreamComplete
        self.http2ManualDataWrites = http2ManualDataWrites
    }
}
