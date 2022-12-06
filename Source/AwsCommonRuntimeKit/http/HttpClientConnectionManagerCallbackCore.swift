//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp

typealias ConnectionContinuation = CheckedContinuation<HttpClientConnection, Error>
/// Core classes have manual memory management.
/// You have to balance the retain & release calls in all cases to avoid leaking memory.
class HttpClientConnectionManagerCallbackCore {
    let connectionManager: HttpClientConnectionManager
    let continuation: ConnectionContinuation

    init(continuation: ConnectionContinuation,
         connectionManager: HttpClientConnectionManager) {
        self.continuation = continuation
        self.connectionManager = connectionManager
    }

    private func passRetained() -> UnsafeMutableRawPointer {
        return Unmanaged.passRetained(self).toOpaque()
    }

    static func acquireConnection(
        continuation: ConnectionContinuation,
        connectionManager: HttpClientConnectionManager
    ) {
        let callbackCore = HttpClientConnectionManagerCallbackCore(
            continuation: continuation,
            connectionManager: connectionManager
        )
        aws_http_connection_manager_acquire_connection(
            connectionManager.rawValue,
            onConnectionSetup,
            callbackCore.passRetained()
        )
    }
}

private func onConnectionSetup(connection: UnsafeMutablePointer<aws_http_connection>?,
                               errorCode: Int32,
                               userData: UnsafeMutableRawPointer!) {
    let callbackDataCore = Unmanaged<HttpClientConnectionManagerCallbackCore>.fromOpaque(userData!).takeRetainedValue()
    if errorCode != AWS_OP_SUCCESS {
        callbackDataCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
        return
    }

    // Success
    let httpConnection = HttpClientConnection(manager: callbackDataCore.connectionManager,
                                              connection: connection!)
    callbackDataCore.continuation.resume(returning: httpConnection)
}
