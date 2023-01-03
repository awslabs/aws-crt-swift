//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCHttp

public class HTTP2Stream: HTTPStream {

    /// Reset the HTTP/2 stream (HTTP/2 only).
    /// Note that if the stream closes before this async call is fully processed, the RST_STREAM frame will not be sent.
    public func resetStream(error: HTTP2Error) throws {
        guard aws_http2_stream_reset(super.rawValue, error.rawValue) == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
    }
}
