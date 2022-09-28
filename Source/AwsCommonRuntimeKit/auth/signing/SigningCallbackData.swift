//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCAuth

public typealias SignedContinuation = CheckedContinuation<HttpRequest, Error>
struct SigningCallbackData {
    public let allocator: Allocator
    public unowned var request: HttpRequest
    public var continuation: SignedContinuation?
    public let signable: UnsafeMutablePointer<aws_signable>?

    public init(allocator: Allocator = defaultAllocator,
                request: HttpRequest,
                signable: UnsafeMutablePointer<aws_signable>?,
                continuation: SignedContinuation? = nil)
    {
        self.allocator = allocator
        self.request = request
        self.signable = signable
        self.continuation = continuation
    }
}
