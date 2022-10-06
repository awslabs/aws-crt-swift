import Foundation
import AwsCommonRuntimeKit
import AwsCCommon
#if os(Linux)
import Glibc
#else
import Darwin
#endif

extension FileHandle {
    func writeln(_ str: String = "") {
        self.write(str.data(using: .utf8)!)
        self.write("\n".data(using: .utf8)!)
    }

    func writeTab() {
        self.write("    ".data(using: .utf8)!)
    }
}

extension String {
    var uppercasingFirst: String {
        return prefix(1).uppercased() + dropFirst()
    }

    var lowercasingFirst: String {
        return prefix(1).lowercased() + dropFirst()
    }

    var camelized: String {
        guard !isEmpty else {
            return ""
        }
        let parts = self.components(separatedBy: "_")
        let first = String(describing: parts.first!).lowercasingFirst
        let rest = parts.dropFirst().map({String($0).uppercasingFirst})
        return ([first] + rest).joined(separator: "")
    }

    func replacingFirstOccurrence(of target: String, with replacement: String) -> String {
        guard let range = self.range(of: target) else { return self }
        return self.replacingCharacters(in: range, with: replacement)
    }
}

@main
struct CRTErrorGenerator {

    private static func createFile() -> FileHandle {
        let fileManager = FileManager.default
        let fileName = "CRTErrorGenerated.swift"
        let path = FileManager.default.currentDirectoryPath + "/Source/AwsCommonRuntimeKit/crt/" + fileName
        fileManager.createFile(atPath: path, contents: nil, attributes: nil)
        let outputStream = FileHandle(forWritingAtPath: path) ?? FileHandle.standardOutput
        return outputStream
    }

    private static func transformErrorName(_ errorName: String) -> String {
        var errorNameReplaced = errorName.replacingOccurrences(of: "ERROR_ERROR", with: "ERROR")
        errorNameReplaced = errorNameReplaced.replacingFirstOccurrence(of: "_ERROR_", with: "_")
        errorNameReplaced = errorNameReplaced.replacingOccurrences(of: "_COND_", with: "_CONDITION_")
        errorNameReplaced = errorNameReplaced.replacingOccurrences(of: "_HASHTBL_", with: "_HASH_TABLE_")
        errorNameReplaced = errorNameReplaced.replacingOccurrences(of: "_INTERUPTED", with: "_INTERRUPTED")
        errorNameReplaced = errorNameReplaced.replacingOccurrences(of: "^AWS_", with: "", options: .regularExpression)
        errorNameReplaced = errorNameReplaced.lowercased().camelized

        // Special cases
        if errorNameReplaced == "oom" {
            return "outOfMemory"
        }

        return errorNameReplaced
    }

    static func main() {
        print(transformErrorName("STRAWS_ASD"))
        let allocator = TracingAllocator(tracingBytesOf: defaultAllocator)

        AwsCommonRuntimeKit.initialize(allocator: allocator)
        let outputStream = createFile()
        /// Generate Header
        outputStream.writeln("// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.")
        outputStream.writeln("// SPDX-License-Identifier: Apache-2.0.")
        outputStream.writeln("// This file is generated using Script/CRTErrorGenerator.swift.")
        outputStream.writeln("// Do not modify this file.")
        outputStream.writeln()

        outputStream.writeln("import AwsCCommon")
        outputStream.writeln()
        outputStream.writeln("/// Error type for CRT errors thrown from C code")
        outputStream.writeln("public enum CRTError: Int32, Error {")

        /// Range is in Hexadecimal.
        let repoNameAndRange = [("AWS-C-COMMON", "0001", "0400"),
                                ("AWS-C-IO", "0400", "0800"),
                                ("AWS-C-HTTP", "0800", "0C00"),
                                ("AWS-C-COMPRESSION", "0C00", "1000"),
                                ("AWS-C-EVENTSTREAM", "1000", "1400"),
                                ("AWS-C-AUTH", "1800", "1C00"),
                                ("AWS-C-CAL", "1C00", "2000"),
                                ("AWS-C-SDKUTILS", "3C00", "4000")
        ]
        outputStream.writeln()
        outputStream.writeTab()
        outputStream.writeln("case unknownErrorCode = -1")
        for (repoName, startRange, endRange) in repoNameAndRange {
            outputStream.writeln()
            outputStream.writeTab()
            outputStream.writeln("/// \(repoName)")
            for errorCode in Int32(startRange, radix: 16)! ..< Int32(endRange, radix: 16)! {
                let errorName = String(cString: aws_error_name(Int32(errorCode)))
                if (errorName != "Unknown Error Code" && errorName != "DEPRECATED_AWS_IO_INVALID_FILE_HANDLE") {
                    outputStream.writeTab()
                    print("\(errorName)  -->  \(transformErrorName(errorName))")
                    outputStream.writeln("case \(transformErrorName(errorName)) = \(errorCode)")
                }
            }
        }

        outputStream.writeln("}")
        AwsCommonRuntimeKit.cleanUp()
    }

}
