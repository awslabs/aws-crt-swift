//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp
import Foundation

public class HTTPStream {
    let rawValue: UnsafeMutablePointer<aws_http_stream>
    var callbackData: HTTPStreamCallbackCore
    var activated: Bool = false
    let lock = NSLock()

    init(rawValue: UnsafeMutablePointer<aws_http_stream>,
         callbackData: HTTPStreamCallbackCore) throws {
        self.callbackData = callbackData
        self.rawValue = rawValue
    }

    /// Opens the Sliding Read/Write Window by the number of bytes passed as an argument for this HTTPStream.
    /// This function should only be called if the user application previously returned less than the length of the
    /// input ByteBuffer from a onIncomingBody() call in a HTTPRequestOptions, and should be &lt;= to the total
    /// number of un-acked bytes.
    /// - Parameters:
    ///   - incrementBy:  How many bytes to increment the sliding window by.
    public func updateWindow(incrementBy: Int) {
        aws_http_stream_update_window(rawValue, incrementBy)
    }

    /// Retrieves the Http Response Status Code
    /// - Returns: The status code as `Int32`
    public func statusCode() throws -> Int {
        var status: Int32 = 0
        if aws_http_stream_get_incoming_response_status(rawValue, &status) != AWS_OP_SUCCESS {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        return Int(status)
    }

    /// Activates the client stream.
    public func activate() throws {
        // Double-Checked Locking
        guard !activated else {
            return
        }

        lock.lock()
        defer {
            lock.unlock()
        }
        guard !activated else {
            return
        }

        callbackData.stream = self
        if aws_http_stream_activate(rawValue) != AWS_OP_SUCCESS {
            callbackData.stream = nil
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        activated = true
    }

    deinit {
        aws_http_stream_release(rawValue)
    }
}
