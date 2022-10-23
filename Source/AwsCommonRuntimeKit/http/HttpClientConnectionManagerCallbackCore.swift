//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp

typealias ConnectionContinuation = CheckedContinuation<HttpClientConnection, Error>
class HttpClientConnectionManagerCallbackCore {
    let connectionManager: HttpClientConnectionManager
    let continuation: ConnectionContinuation

    init(continuation: ConnectionContinuation,
         connectionManager: HttpClientConnectionManager) {
        self.continuation = continuation
        self.connectionManager = connectionManager
    }

    func retainedAcquireConnection() {
        let retainedSelf = Unmanaged.passRetained(self).toOpaque()
        aws_http_connection_manager_acquire_connection(connectionManager.rawValue, onConnectionSetup, retainedSelf)
    }
}

func onConnectionSetup(connection: UnsafeMutablePointer<aws_http_connection>?,
                       errorCode: Int32,
                       userData: UnsafeMutableRawPointer!) {
    let callbackDataCore = Unmanaged<HttpClientConnectionManagerCallbackCore>.fromOpaque(userData!).takeRetainedValue()
    if errorCode != AWS_OP_SUCCESS {
        callbackDataCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
        return
    }
    //TODO: Is this possible? If not, use !
    guard let connection = connection else {
        callbackDataCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
        return
    }
    let httpConnection = HttpClientConnection(manager: callbackDataCore.connectionManager,
            connection: connection)
    callbackDataCore.continuation.resume(returning: httpConnection)
}
