//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp

typealias ConnectionContinuation = CheckedContinuation<HTTPClientConnection, Error>
/// Core classes have manual memory management.
/// You have to balance the retain & release calls in all cases to avoid leaking memory.
class HTTPClientConnectionManagerCallbackCore {
    let connectionManager: HTTPClientConnectionManager
    let continuation: ConnectionContinuation

    init(continuation: ConnectionContinuation,
         connectionManager: HTTPClientConnectionManager) {
        self.continuation = continuation
        self.connectionManager = connectionManager
    }

    private func passRetained() -> UnsafeMutableRawPointer {
        return Unmanaged.passRetained(self).toOpaque()
    }

    static func acquireConnection(
        continuation: ConnectionContinuation,
        connectionManager: HTTPClientConnectionManager
    ) {
        let callbackCore = HTTPClientConnectionManagerCallbackCore(
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
    let callbackDataCore = Unmanaged<HTTPClientConnectionManagerCallbackCore>.fromOpaque(userData!).takeRetainedValue()
    if errorCode != AWS_OP_SUCCESS {
        callbackDataCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
        return
    }

    // Success
    let httpConnection = HTTPClientConnection(manager: callbackDataCore.connectionManager,
                                              connection: connection!)
    callbackDataCore.continuation.resume(returning: httpConnection)
}
