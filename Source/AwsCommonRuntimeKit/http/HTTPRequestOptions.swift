//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import Foundation

public struct HTTPRequestOptions {
    public typealias OnIncomingHeaders = (_ stream: HTTPStream,
                                          _ headerBlock: HTTPHeaderBlock,
                                          _ headers: [HTTPHeader]) -> Void
    public typealias OnIncomingHeadersBlockDone = (_ stream: HTTPStream,
                                                   _ headerBlock: HTTPHeaderBlock) -> Void
    public typealias OnIncomingBody = (_ stream: HTTPStream, _ bodyChunk: Data) -> Void
    public typealias OnStreamComplete = (_ stream: HTTPStream, _ error: CRTError?) -> Void

    let request: HTTPRequest
    public let onIncomingHeaders: OnIncomingHeaders
    public let onIncomingHeadersBlockDone: OnIncomingHeadersBlockDone
    public let onIncomingBody: OnIncomingBody
    public let onStreamComplete: OnStreamComplete

    public init(request: HTTPRequest,
                onIncomingHeaders: @escaping OnIncomingHeaders,
                onIncomingHeadersBlockDone: @escaping OnIncomingHeadersBlockDone,
                onIncomingBody: @escaping OnIncomingBody,
                onStreamComplete: @escaping OnStreamComplete) {
        self.request = request
        self.onIncomingHeaders = onIncomingHeaders
        self.onIncomingHeadersBlockDone = onIncomingHeadersBlockDone
        self.onIncomingBody = onIncomingBody
        self.onStreamComplete = onStreamComplete
    }
}
