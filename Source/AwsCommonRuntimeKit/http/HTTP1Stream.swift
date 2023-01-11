//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp
import Foundation

public class HTTP1Stream: HTTPStream {
    /// Stream keeps a reference to HttpConnection to keep it alive
    private let httpConnection: HTTPClientConnection

    // Called by HTTPClientConnection
    init(
        httpConnection: HTTPClientConnection,
        options: aws_http_make_request_options,
        callbackData: HTTPStreamCallbackCore) throws {
        guard let rawValue = withUnsafePointer(
                to: options, { aws_http_connection_make_request(httpConnection.rawValue, $0) }) else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        self.httpConnection = httpConnection
        try super.init(rawValue: rawValue, callbackData: callbackData)
    }
}
