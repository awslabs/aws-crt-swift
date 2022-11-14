//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

typealias ResourceContinuation = CheckedContinuation<String?, Error>
class IMDSResourceCallbackCore {
    let continuation: ResourceContinuation

    init(continuation: ResourceContinuation) {
        self.continuation = continuation
    }

    private func getRetainedSelf() -> UnsafeMutableRawPointer {
        return Unmanaged<HostResolverCore>.passRetained(self).toOpaque()
    }

    public static func getRetainedResource(resourcePath: String, client: IMDSClient, continuation: ResourceContinuation) async throws -> String? {
        let core = IMDSResourceCallbackCore(continuation: continuation)
        let retainedSelf = core.getRetainedSelf()

    }


    private func release() {
        Unmanaged.passUnretained(self).release()
    }
}
