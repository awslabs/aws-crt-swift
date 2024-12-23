//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

// TODO: Remove userData property once it is no longer needed for accountId on credentials

/// Core classes have manual memory management.
/// You have to balance the retain & release calls in all cases to avoid leaking memory.
class ContinuationCore<T> {
    let continuation: CheckedContinuation<T, Error>
    let userData: [String: Any]?

    init(continuation: CheckedContinuation<T, Error>, userData: [String: Any]? = nil) {
        self.continuation = continuation
        self.userData = userData
    }

    func passRetained() -> UnsafeMutableRawPointer {
        return Unmanaged.passRetained(self).toOpaque()
    }

    func release() {
        Unmanaged.passUnretained(self).release()
    }
}
