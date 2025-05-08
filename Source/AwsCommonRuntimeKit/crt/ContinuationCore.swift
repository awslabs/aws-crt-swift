//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

/// Core classes have manual memory management.
/// You have to balance the retain & release calls in all cases to avoid leaking memory.
class ContinuationCore<T> {
  let continuation: CheckedContinuation<T, Error>

  init(continuation: CheckedContinuation<T, Error>) {
    self.continuation = continuation
  }

  func passRetained() -> UnsafeMutableRawPointer {
    return Unmanaged.passRetained(self).toOpaque()
  }

  func release() {
    Unmanaged.passUnretained(self).release()
  }
}
