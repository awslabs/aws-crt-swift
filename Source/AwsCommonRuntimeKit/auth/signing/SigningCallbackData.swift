//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.


public typealias OnRequestSigningComplete = (HttpRequest, Int) -> Void

struct SigningCallbackData {
    public let allocator: Allocator
    public let request: HttpRequest
    public let onRequestSigningComplete: OnRequestSigningComplete
    
    public init(allocator: Allocator = defaultAllocator,
                request: HttpRequest,
                onRequestSigningComplete: @escaping OnRequestSigningComplete) {
        self.allocator = allocator
        self.request = request
        self.onRequestSigningComplete = onRequestSigningComplete
    }
}

