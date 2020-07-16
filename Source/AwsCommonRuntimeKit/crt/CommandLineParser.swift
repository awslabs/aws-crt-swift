//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import Foundation
import AwsCCommon

enum CliOptionsType {
    case none
    case required
    case optional
}
extension CliOptionsType {
    var rawValue: aws_cli_options_has_arg {
        switch self {
        case .none:  return AWS_CLI_OPTIONS_NO_ARGUMENT
        case .required: return AWS_CLI_OPTIONS_REQUIRED_ARGUMENT
        case .optional: return AWS_CLI_OPTIONS_OPTIONAL_ARGUMENT
        }
    }
}

extension aws_cli_options_has_arg {
    var cliOptionsType: CliOptionsType! {
        switch self.rawValue {
        case AWS_CLI_OPTIONS_NO_ARGUMENT.rawValue: return CliOptionsType.none
        case AWS_CLI_OPTIONS_REQUIRED_ARGUMENT.rawValue:  return CliOptionsType.required
        case AWS_CLI_OPTIONS_OPTIONAL_ARGUMENT.rawValue: return CliOptionsType.optional
        default:
            assertionFailure("Unknown aws_cli_options_has_arg: \(String(describing: self))")
            return nil // <- Makes compiler happy, but we'd have halted right before reaching here
        }
    }
}

public struct CommandLineParser {
    
    
    public static func parseArguments(argc: Int32, arguments: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?> , optionString: String, options: [aws_cli_option], optionIndex: inout Int32) -> [String: Any] {
        
        var optionChars = [String: Any]()
  
        let char = aws_cli_getopt_long(argc, arguments, optionString.asCStr(), options, &optionIndex)
        if let char = char.toString() {
            optionChars[char] = aws_cli_optarg
        }

        return optionChars
    }
}

extension Int32 {
    public func toString() -> String? {
        let u = UnicodeScalar(Int(self))
        // Convert UnicodeScalar to a String.
        if let u = u {
            return String(u)
        }
        return nil
    }
}
