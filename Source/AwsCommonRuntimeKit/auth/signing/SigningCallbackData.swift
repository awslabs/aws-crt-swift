//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCAuth
//TODO: fix SigningCallbackData.
// It should not have signable pointer if we can avoid it.
// Try to get rid of unowned HttpRequest as it should stay alive until callback has fired.
typealias SignedContinuation = CheckedContinuation<HttpRequest, Error>
struct SigningCallbackData {
    let allocator: Allocator
    unowned var request: HttpRequest
    var continuation: SignedContinuation
    let signable: UnsafeMutablePointer<aws_signable>?

    init(allocator: Allocator = defaultAllocator,
         request: HttpRequest,
         signable: UnsafeMutablePointer<aws_signable>?,
         continuation: SignedContinuation) {
        self.allocator = allocator
        self.request = request
        self.signable = signable
        self.continuation = continuation
    }
}
