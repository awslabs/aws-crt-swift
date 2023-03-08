//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import Foundation

/// Definition for outgoing request and callbacks to receive response.
public struct HTTPRequestOptions {

    /// Callback to receive interim response
    public typealias OnInterimResponse = (_ statusCode: UInt32,
                                          _ headers: [HTTPHeader]) throws -> Void
    /// Callback to receive main headers
    public typealias OnResponse = (_ statusCode: UInt32,
                                   _ headers: [HTTPHeader]) throws -> Void
    /// Callback to receive the incoming body
    public typealias OnIncomingBody = (_ bodyChunk: Data) throws -> Void
    /// Callback to receive trailer headers
    public typealias OnTrailer = (_ headers: [HTTPHeader]) throws -> Void
    /// Callback to know when request is completed, whether successful or unsuccessful
    public typealias OnStreamComplete = (_ result: Result<UInt32, CommonRunTimeError>) -> Void

    /// Outgoing request.
    let request: HTTPRequestBase

    /// Invoked 0+ times if informational 1xx interim responses are received.
    public let onInterimResponse: OnInterimResponse?

    /// Invoked when main response headers are received.
    public let onResponse: OnResponse

    /// Invoked repeatedly as body data is received.
    public let onIncomingBody: OnIncomingBody

    /// Invoked when trailer headers are received.
    public let onTrailer: OnTrailer?

    /// Invoked when request/response stream is complete, whether successful or unsuccessful
    public let onStreamComplete: OnStreamComplete

    /// When using HTTP/2, set http2ManualDataWrites to true to specify that request body data will be provided over time.
    /// The stream will only be polled for writing when data has been supplied via `HTTP2Stream.writeData`
    public var http2ManualDataWrites: Bool = false

    public init(request: HTTPRequestBase,
                onInterimResponse: OnInterimResponse? = nil,
                onResponse: @escaping OnResponse,
                onIncomingBody: @escaping OnIncomingBody,
                onTrailer: OnTrailer? = nil,
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
