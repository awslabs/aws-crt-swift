//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCHttp

/// Predefined configurable options for HTTP2 (RFC-7540 6.5.2).
/// Nil means use default values
public struct HTTP2Settings: CStruct {
    public var headerTableSize: UInt32?
    public var enablePush: Bool?
    public var maxConcurrentStreams: UInt32?
    public var initialWindowSize: UInt32?
    public var maxFrameSize: UInt32?
    public var maxHeaderListSize: UInt32?

    typealias RawType = [aws_http2_setting]
    func withCStruct<Result>(_ body: ([aws_http2_setting]) -> Result
    ) -> Result {
        var http2SettingList = [aws_http2_setting]()
        if let value = headerTableSize {
            http2SettingList.append(
                aws_http2_setting(
                    id: AWS_HTTP2_SETTINGS_HEADER_TABLE_SIZE,
                    value: value))
        }
        if let value = enablePush {
            http2SettingList.append(
                aws_http2_setting(
                    id: AWS_HTTP2_SETTINGS_ENABLE_PUSH,
                    value: value.uintValue))
        }
        if let value = maxConcurrentStreams {
            http2SettingList.append(
                aws_http2_setting(
                    id: AWS_HTTP2_SETTINGS_MAX_CONCURRENT_STREAMS,
                    value: value))
        }
        if let value = initialWindowSize {
            http2SettingList.append(
                aws_http2_setting(
                    id: AWS_HTTP2_SETTINGS_INITIAL_WINDOW_SIZE,
                    value: value))
        }
        if let value = maxFrameSize {
            http2SettingList.append(
                aws_http2_setting(
                    id: AWS_HTTP2_SETTINGS_MAX_FRAME_SIZE,
                    value: value))
        }
        if let value = maxHeaderListSize {
            http2SettingList.append(
                aws_http2_setting(
                    id: AWS_HTTP2_SETTINGS_MAX_HEADER_LIST_SIZE,
                    value: value))
        }
        return body(http2SettingList)
    }
}
