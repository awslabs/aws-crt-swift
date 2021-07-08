//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

public struct CRTCredentialsProviderShutdownOptions {
    public typealias ShutDownCallback = CheckedContinuation<Void, Never>

    public var shutDownCallback: ShutDownCallback?

    public init(shutDownCallback: ShutDownCallback? = nil) {
        self.shutDownCallback = shutDownCallback

    }
}
