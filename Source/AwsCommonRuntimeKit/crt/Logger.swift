//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCCommon
import Foundation

public enum LogTarget {
    case standardOutput
    case standardError
    case filePath(String) 
}

public struct Logger {
    private static var logger: aws_logger? = nil
    private static let lock = NSLock()

    /// Initializes the CRT logger based on the specified log target and log level. The CRT logger must be only initialized once in your application. Initializing the logger multiple times is not supported.
    /// - Parameters:
    ///   - target: The logging target, which can be standard output, standard error, or a custom file path.
    ///   - level: The logging level, represented by the `LogLevel` enum.
    /// - Throws: CommonRunTimeError.crtException
    public static func initialize(target: LogTarget, level: LogLevel) throws {
        lock.lock()
        defer { lock.unlock() }

        // Check if the logger is already initialized
        guard logger == nil else {
            throw CommonRunTimeError.crtError(CRTError(code: AWS_ERROR_UNSUPPORTED_OPERATION.rawValue, context: "Initializing the CRT Logger multiple times is not supported."))
        }

        // Initialize the logger
        logger = aws_logger()
        var options = aws_logger_standard_options()
        options.level = level.rawValue

        // Set options based on the logging target
        switch target {
        case .standardOutput:
            options.file = stdout
        case .standardError:
            options.file = stderr
        case .filePath(let filePath):
            filePath.withCString { cFilePath in
                options.filename = cFilePath
            }
        }

        // Initialize and set the logger
        aws_logger_init_standard(&logger!, allocator.rawValue, &options)
        aws_logger_set(&logger!)
    }
}

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
