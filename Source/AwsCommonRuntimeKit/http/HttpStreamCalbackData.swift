//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import Foundation

class HttpStreamCallbackData {
    let requestOptions: HttpRequestOptions
    //Todo: How to acquire and release stream?
    var stream: HttpStream?

    init(requestOptions: HttpRequestOptions) {
        self.requestOptions = requestOptions
    }
}
