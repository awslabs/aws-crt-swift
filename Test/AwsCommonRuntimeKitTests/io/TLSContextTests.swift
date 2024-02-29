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
