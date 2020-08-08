//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

public typealias OnSigningComplete = (SigningResult?, HttpRequest, Int) -> Void

struct SigningCallbackData {
    public let allocator: Allocator
    public unowned var request: HttpRequest
    public let onSigningComplete: OnSigningComplete

    public init(allocator: Allocator = defaultAllocator,
                request: HttpRequest,
                onSigningComplete: @escaping OnSigningComplete) {
        self.allocator = allocator
        self.request = request
        self.onSigningComplete = onSigningComplete
    }
}
