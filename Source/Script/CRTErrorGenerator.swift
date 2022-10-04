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
        var errorNameReplaced = errorName.replacingOccurrences(of: "AWS_", with: "")
        errorNameReplaced = errorNameReplaced.replacingOccurrences(of: "ERROR_", with: "")
        errorNameReplaced = errorNameReplaced.replacingOccurrences(of: "COND", with: "CONDITION")
        errorNameReplaced = errorNameReplaced.replacingOccurrences(of: "HASHTBL", with: "HASH_TABLE")
        errorNameReplaced = errorNameReplaced.replacingOccurrences(of: "INTERUPTED", with: "INTERRUPTED")
        errorNameReplaced = errorNameReplaced.lowercased().camelized
        return errorNameReplaced
    }

    static func main() {

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
                if errorName != "Unknown Error Code" {
                    outputStream.writeTab()
                    outputStream.writeln("case \(transformErrorName(errorName)) = \(errorCode)")
                }
            }
        }

        outputStream.writeln("}")
        AwsCommonRuntimeKit.cleanUp()
    }

}
