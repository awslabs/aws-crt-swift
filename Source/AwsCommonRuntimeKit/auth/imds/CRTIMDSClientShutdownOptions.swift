//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

public struct CRTIDMSClientShutdownOptions {
    public typealias ShutDownCallback = () -> Void

    public let shutDownCallback: ShutDownCallback

    public init(shutDownCallback: @escaping ShutDownCallback) {
        self.shutDownCallback = shutDownCallback

    }
}
