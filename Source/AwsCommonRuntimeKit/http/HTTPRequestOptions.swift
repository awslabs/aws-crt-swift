//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import Foundation

public struct HTTPRequestOptions {

    public typealias OnInterimResponse = (_ statusCode: Int32,
                                          _ headers: [HTTPHeader]) -> Void
    public typealias OnResponse = (_ statusCode: Int32,
                                   _ headers: [HTTPHeader]) -> Void
    public typealias OnTrailer = (_ headers: [HTTPHeader]) -> Void
    public typealias OnIncomingBody = (_ bodyChunk: Data) -> Void
    public typealias OnStreamComplete = (_ result: Result<Int32, CommonRunTimeError>) -> Void

    /// Outgoing request.
    let request: HTTPRequestBase

    /// Invoked when informational 1xx interim response is received
    public let onInterimResponse: OnInterimResponse?

    /// Invoked when main response headers are received.
    public let onResponse: OnResponse

    /// Invoked when trailer response headers are received.
    public let onTrailer: OnTrailer?

    /// Invoked repeatedly as body data is received.
    public let onIncomingBody: OnIncomingBody

    /// Invoked when request/response stream is complete, whether successful or unsuccessful
    public let onStreamComplete: OnStreamComplete

    /// When using HTTP/2, set http2ManualDataWrites to true to specify that request body data will be provided over time.
    /// The stream will only be polled for writing when data has been supplied via `HTTP2Stream.writeData`
    public var http2ManualDataWrites: Bool = false

    public init(request: HTTPRequestBase,
                onInterimResponse: OnInterimResponse? = nil,
                onResponse: @escaping OnResponse,
                onTrailer: OnTrailer? = nil,
                onIncomingBody: @escaping OnIncomingBody,
                onStreamComplete: @escaping OnStreamComplete,
                http2ManualDataWrites: Bool = false) {
        self.request = request
        self.onInterimResponse = onInterimResponse
        self.onResponse = onResponse
        self.onTrailer = onTrailer
        self.onIncomingBody = onIncomingBody
        self.onStreamComplete = onStreamComplete
        self.http2ManualDataWrites = http2ManualDataWrites
    }
}
