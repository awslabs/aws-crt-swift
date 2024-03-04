//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
import Foundation
@testable import AwsCommonRuntimeKit

class TLSContextTests: XCBaseTestCase {

  func testCreateTlsContextWithOptions() throws {
    let options = TLSContextOptions()
    let context = try TLSContext(options: options, mode: .client)
    _ = TLSConnectionOptions(context: context)
  }

    static func run_shell(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/zsh"
        task.standardInput = nil
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!
        
        return output
    }
    
    func testTlsWithSecurityDefaultKeychain() throws
    {
        print(TLSContextTests.run_shell("security default-keychain"));
    }


    func testCreateTlsContextWithFilePath() throws{
        try skipIfiOS()
        try skipIftvOS()
        try skipIfwatchOS()
        let cert_path = try GetEnvironmentVarOrSkip(environmentVarName: "AWS_TEST_MQTT311_IOT_CORE_X509_CERT")
        let private_key_path = try GetEnvironmentVarOrSkip(environmentVarName: "AWS_TEST_MQTT311_IOT_CORE_X509_KEY")
        let options = try TLSContextOptions.makeMtlsFromFilePath(certificatePath: cert_path!, privateKeyPath: private_key_path!)
        let context = try TLSContext(options: options, mode: .client)
        _ = TLSConnectionOptions(context: context)
    }
    

}
