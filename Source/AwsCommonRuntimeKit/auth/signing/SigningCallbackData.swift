//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.


public typealias OnRequestSigningComplete = (HttpRequest, Int) -> Void

struct SigningCallbackData {
    
    public let request: HttpRequest
    public let onRequestSigningComplete: OnRequestSigningComplete
    
    public init(request: HttpRequest,
                onRequestSigningComplete: @escaping OnRequestSigningComplete) {
        self.request = request
        self.onRequestSigningComplete = onRequestSigningComplete
    }
}

