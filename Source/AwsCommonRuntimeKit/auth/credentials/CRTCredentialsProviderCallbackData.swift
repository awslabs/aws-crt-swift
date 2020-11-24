//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

public struct CRTCredentialsProviderCallbackData {
    public typealias OnCredentialsResolved = (CRTCredentials?, CRTError) -> Void
    public var onCredentialsResolved: OnCredentialsResolved?
    public let allocator: Allocator

    public init(allocator: Allocator,
                onCredentialsResolved: OnCredentialsResolved? = nil) {
        self.onCredentialsResolved = onCredentialsResolved
        self.allocator = allocator
    }
}
