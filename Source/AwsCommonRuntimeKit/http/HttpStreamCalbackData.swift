//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import Foundation

class HttpStreamCallbackData {
    let requestOptions: HttpRequestOptions
    var stream: HttpStream?

    init(requestOptions: HttpRequestOptions) {
        self.requestOptions = requestOptions
    }
}
