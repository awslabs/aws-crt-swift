//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCCommon
import AwsCIo
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
    public static var allCases: [LogLevel] {
        return [.none, .fatal, .error, .warn, .info, .debug, .trace]
    }
    
    public init?(rawValue: aws_log_level) {
        let value = Self.allCases.first(where: {$0.rawValue == rawValue})
        self = value ?? .none
    }
    public var rawValue: aws_log_level {
        switch self {
        case .none:  return AWS_LL_NONE
        case .fatal:  return AWS_LL_FATAL
        case .error: return AWS_LL_ERROR
        case .warn: return AWS_LL_WARN
        case .info: return AWS_LL_INFO
        case .debug: return AWS_LL_DEBUG
        case .trace: return AWS_LL_TRACE
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
