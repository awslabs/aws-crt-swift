//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import Foundation
import AwsCCommon

enum CliOptionsType {
    case none
    case required
    case optional
}
extension CliOptionsType: RawRepresentable, CaseIterable {
    public static var allCases: [CliOptionsType] {
        return [.none, .required, .optional]
    }
    
    public init(rawValue: aws_cli_options_has_arg){
        let value = Self.allCases.first(where: {$0.rawValue == rawValue})
        self = value ?? .none
    }
    
    public var rawValue: aws_cli_options_has_arg {
        switch self {
        case .none:  return AWS_CLI_OPTIONS_NO_ARGUMENT
        case .required: return AWS_CLI_OPTIONS_REQUIRED_ARGUMENT
        case .optional: return AWS_CLI_OPTIONS_OPTIONAL_ARGUMENT
        }
    }
}

public struct CommandLineParser {
    
    public static func parseArguments(argc: Int32, arguments: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?> , optionString: String, options: [aws_cli_option], optionIndex: inout Int32) -> [String: String] {
        
        var optionChars = [String: String]()
  
        let char = aws_cli_getopt_long(argc, arguments, optionString.asCStr(), options, &optionIndex)
        if let char = char.toString() {
            optionChars[char] = String(cString: aws_cli_optarg)
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
