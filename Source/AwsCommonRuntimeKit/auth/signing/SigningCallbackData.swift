//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCAuth

public typealias OnSigningComplete = (SigningResult?, HttpRequest, CRTError) -> Void

struct SigningCallbackData {
    public let allocator: Allocator
    public unowned var request: HttpRequest
    public var onSigningComplete: OnSigningComplete
    public let signable: UnsafeMutablePointer<aws_signable>?

    public init(allocator: Allocator = defaultAllocator,
                request: HttpRequest,
                signable: UnsafeMutablePointer<aws_signable>?) {
        self.allocator = allocator
        self.request = request
        self.signable = signable
        self.onSigningComplete = { result, request, error in
            
        }
    }
}
