//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest

@testable import AwsCommonRuntimeKit

class TLSContextTests: XCBaseTestCase {

  func testCreateTlsContextWithOptions() throws {
    let options = TLSContextOptions()
    let context = try TLSContext(options: options, mode: .client)
    _ = TLSConnectionOptions(context: context)
  }

  #if os(macOS) || os(Linux) || os(Android)
    func testCreateTlsContextWithFilePath() throws {

      let certPath = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT311_IOT_CORE_X509_CERT")
      let privateKeyPath = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT311_IOT_CORE_X509_KEY")

      let options = try TLSContextOptions.makeMTLS(
        certificatePath: certPath, privateKeyPath: privateKeyPath)

      let context = try TLSContext(options: options, mode: .client)
      _ = TLSConnectionOptions(context: context)
    }
  #endif

  #if os(macOS) || os(Linux) || os(Android)
    func testCreateTlsContextWithData() throws {

      let certPath = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT311_IOT_CORE_X509_CERT")
      let privateKeyPath = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT311_IOT_CORE_X509_KEY")

      let certificateData = try Data(contentsOf: URL(fileURLWithPath: certPath))
      let privateKeyData = try Data(contentsOf: URL(fileURLWithPath: privateKeyPath))

      let options = try TLSContextOptions.makeMTLS(
        certificateData: certificateData, privateKeyData: privateKeyData)

      let context = try TLSContext(options: options, mode: .client)
      _ = TLSConnectionOptions(context: context)
    }
  #endif

  #if AWS_USE_SECITEM
    func testCreateTlsContextWithSecitemOptions() throws {
      try skipIfPlatformDoesntSupportTLS()
      let certPath = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT311_IOT_CORE_X509_CERT")
      let privateKeyPath = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT311_IOT_CORE_X509_KEY")

      let certificateData = try Data(contentsOf: URL(fileURLWithPath: certPath))
      let privateKeyData = try Data(contentsOf: URL(fileURLWithPath: privateKeyPath))

      let options = try TLSContextOptions.makeMTLS(
        certificateData: certificateData, privateKeyData: privateKeyData)
      try options.setSecitemLabels(certLabel: "TEST_CERT_LABEL", keyLabel: "TEST_KEY_LABEL")

      let context = try TLSContext(options: options, mode: .client)
      _ = TLSConnectionOptions(context: context)
    }
  #endif
}
