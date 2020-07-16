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
    
    public static func parseArguments(argc: Int32, arguments: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>, optionString: String, options: [aws_cli_option]) -> [Character] {
        var optionChars = [Character]()
        let chars = aws_cli_getopt_long(argc, arguments, optionString.asCStr(), options, nil)
        optionChars.append(chars.toChar()!)
//        for argument in arguments {
//            let bytes = [argument.asCStr()].map { (cString) -> UnsafeMutablePointer<Int8>?  in
//                return UnsafeMutablePointer<Int8>(mutating: cString)
//            }
//
//            let char = aws_cli_getopt_long(argc, bytes, optionString.asCStr(), options, nil)
//            if let char = char.toChar() {
//                optionChars.append(char)
//            }
//
//        }
        return optionChars
    }
}

extension Int32 {
    func toChar() -> Character? {
        let u = UnicodeScalar(Int(self))
        // Convert UnicodeScalar to a Character.
        if let u = u {
            return Character(u)
        }
        return nil
    }
}
