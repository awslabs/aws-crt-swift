//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCCommon

public enum LogLevel {
    case none
    case fatal
    case error
    case warn
    case info
    case debug
    case trace
}

extension LogLevel {

    public static func fromString(string: String) -> LogLevel {
        switch string {
        case "TRACE":
            return .trace
        case "INFO":
            return .info
        case "WARN":
            return .warn
        case "DEBUG":
            return .debug
        case "FATAL":
            return .fatal
        case "ERROR":
            return .error
        case "NONE":
            return .none
        default:
            return .none
        }
    }

    var rawValue: aws_log_level {
        switch self {
        case .none: return AWS_LL_NONE
        case .fatal: return AWS_LL_FATAL
        case .error: return AWS_LL_ERROR
        case .warn: return AWS_LL_WARN
        case .info: return AWS_LL_INFO
        case .debug: return AWS_LL_DEBUG
        case .trace: return AWS_LL_TRACE
        }
    }
}
