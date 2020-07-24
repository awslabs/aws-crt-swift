//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCCommon
import Foundation

public enum LogLevel {
    case none
    case fatal
    case error
    case warn
    case info
    case debug
    case trace
}

extension LogLevel: RawRepresentable, CaseIterable {

    public init(rawValue: aws_log_level) {
        let value = Self.allCases.first(where: {$0.rawValue == rawValue})
        self = value ?? .none
    }

    public var rawValue: aws_log_level {
        switch self {
        case .none: return unsafeBitCast(AWS_LOG_LEVEL_NONE, to: aws_log_level.self)
        case .fatal: return unsafeBitCast(AWS_LOG_LEVEL_FATAL, to: aws_log_level.self)
        case .error: return unsafeBitCast(AWS_LOG_LEVEL_ERROR, to: aws_log_level.self)
        case .warn: return unsafeBitCast(AWS_LOG_LEVEL_WARN, to: aws_log_level.self)
        case .info: return unsafeBitCast(AWS_LOG_LEVEL_INFO, to: aws_log_level.self)
        case .debug: return unsafeBitCast(AWS_LOG_LEVEL_DEBUG, to: aws_log_level.self)
        case .trace: return unsafeBitCast(AWS_LOG_LEVEL_TRACE, to: aws_log_level.self)
        }
    }
}

public class Logger {
    var logger: aws_logger

    public init(pipe: UnsafeMutablePointer<FILE>?, level: LogLevel, allocator: Allocator = defaultAllocator) {
        logger = aws_logger()
        var options = aws_logger_standard_options()
        options.level = level.rawValue
        options.file = pipe
        aws_logger_init_standard(&logger, allocator.rawValue, &options)
        aws_logger_set(&logger)
    }

    public init(filePath: String, level: LogLevel, allocator: Allocator = defaultAllocator) {
        let filePathCStr = (filePath as NSString).utf8String
        logger = aws_logger()
        var options = aws_logger_standard_options()
        options.level = level.rawValue
        options.filename = filePathCStr
        aws_logger_init_standard(&logger, allocator.rawValue, &options)
        aws_logger_set(&logger)
    }

    deinit {
        aws_logger_clean_up(&logger)
    }
}
