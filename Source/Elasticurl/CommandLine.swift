//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import Foundation
import AwsCCommon
// swiftlint:disable trailing_whitespace

struct CommandLineParser {
    /// A function to parse command line arguments
    /// - Parameters:
    ///   - argc: The number of arguments
    ///   - arguments: A pointer to a string pointer of the arguments
    ///   - optionString: a `String` with all the possible options that could be passed in
    ///   - options: An array of `[aws_cli_option]` containing all the possible option keys as objects
    ///   with additional metadata
    /// - Returns: A dictionary of`[String: Any] ` with `String` as the name of the flag and `Any` as the
    /// value passed in
    public static func parseArguments(argc: Int32,
                                      arguments: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>,
                                      optionString: String,
                                      options: [aws_cli_option]) -> [String: Any] {
        var argumentsDict = [String: Any]()
        while true {
            var optionIndex: Int32 = 0
            let opt = aws_cli_getopt_long(argc, arguments, optionString, options, &optionIndex)
            if opt == -1 || opt == 0 {
                break
            }
            
            if let char = opt.toString() {
                if aws_cli_optarg != nil {
                    argumentsDict[char] = String(cString: aws_cli_optarg)
                } else {
                    // if argument doesnt have a value just mark it as present in the dictionary
                    argumentsDict[char] = true
                }
            }
        }
        
        return argumentsDict
    }
}

enum CLIHasArg {
    case none
    case required
    case optional
}

extension CLIHasArg: RawRepresentable, CaseIterable {
    public init(rawValue: aws_cli_options_has_arg) {
        let value = Self.allCases.first(where: {$0.rawValue == rawValue})
        self = value ?? .none
    }
    public var rawValue: aws_cli_options_has_arg {
        switch self {
        case .none: return AWS_CLI_OPTIONS_NO_ARGUMENT
        case .required: return AWS_CLI_OPTIONS_REQUIRED_ARGUMENT
        case .optional: return AWS_CLI_OPTIONS_OPTIONAL_ARGUMENT
        }
    }
}

public class AWSCLIOption {
    let rawValue: aws_cli_option
    let name: UnsafeMutablePointer<CChar>
    init(name: String, hasArg: CLIHasArg, flag: UnsafeMutablePointer<Int32>? = nil, val: String) {
        self.name = strdup(name)!
        self.rawValue = aws_cli_option(name: self.name, has_arg: hasArg.rawValue, flag: flag, val: Int32(bitPattern: UnicodeScalar(val)?.value ?? 0))
    }

    deinit {
        free(name)
    }
}
