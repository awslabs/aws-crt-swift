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

extension LogLevel: RawRepresentable, CaseIterable {

	public init(rawValue: aws_log_level) {
		let value = Self.allCases.first(where: {$0.rawValue == rawValue})
		self = value ?? .none
	}

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