//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCCommon

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
        logger = aws_logger()

        filePath.withCString { cFilePath in
            var options = aws_logger_standard_options()
            options.level = level.rawValue
            options.filename = cFilePath
            aws_logger_init_standard(&logger, allocator.rawValue, &options)
            aws_logger_set(&logger)
        }
    }

    deinit {
        aws_logger_clean_up(&logger)
        aws_logger_set(nil)
    }
}
