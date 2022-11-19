//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import Foundation

public struct HttpRequestOptions {
    public typealias OnIncomingHeaders = (_ stream: HttpStream,
                                          _ headerBlock: HttpHeaderBlock,
                                          _ headers: HttpHeaders) -> Void
    public typealias OnIncomingHeadersBlockDone = (_ stream: HttpStream,
                                                   _ headerBlock: HttpHeaderBlock) -> Void
    public typealias OnIncomingBody = (_ stream: HttpStream, _ bodyChunk: Data) -> Void
    public typealias OnStreamComplete = (_ stream: HttpStream, _ error: CRTError?) -> Void

    let request: HttpRequest
    public let onIncomingHeaders: OnIncomingHeaders
    public let onIncomingHeadersBlockDone: OnIncomingHeadersBlockDone
    public let onIncomingBody: OnIncomingBody
    public let onStreamComplete: OnStreamComplete

    public init(request: HttpRequest,
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
