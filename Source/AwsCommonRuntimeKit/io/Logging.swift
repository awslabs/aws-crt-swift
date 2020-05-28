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

private extension LogLevel {
  var rawValue: aws_log_level {
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

private extension aws_log_level {
  var logLevel: LogLevel! {
    switch self.rawValue {
      case AWS_LL_NONE.rawValue:  return .none
      case AWS_LL_FATAL.rawValue:  return .fatal
      case AWS_LL_ERROR.rawValue: return .error
      case AWS_LL_WARN.rawValue: return .warn
      case AWS_LL_INFO.rawValue: return .info
      case AWS_LL_DEBUG.rawValue: return .debug
      case AWS_LL_TRACE.rawValue: return .trace
      default:
        assertionFailure("Unknown aws_log_level: \(String(describing: self))")
        return nil // <- Makes compiler happy, but we'd have halted right before reaching here
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