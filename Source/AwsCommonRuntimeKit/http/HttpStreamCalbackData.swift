//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import Foundation

class HttpStreamCallbackData {
    let requestOptions: HttpRequestOptions
    var stream: HttpStream?
    // Todo: maybe make it non nullable
    let continuation: CheckedContinuation<Int, Error>?

    init(requestOptions: HttpRequestOptions, continuation: CheckedContinuation<Int, Error>? = nil) {
        self.requestOptions = requestOptions
        self.continuation = continuation
    }
}
