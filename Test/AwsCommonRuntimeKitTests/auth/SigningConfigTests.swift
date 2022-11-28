//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
import AwsCCommon
@testable import AwsCommonRuntimeKit

class AWSSigningConfigTests: CrtXCBaseTestCase {

    func testSigningConfig() async throws {
        let signingConfig = SigningConfig(algorithm: SigningAlgorithmType.signingV4Asymmetric,
                signatureType: SignatureType.requestChunk,
                service: "testService",
                region: "testRegion",
                date: Date(timeIntervalSinceNow: 100),
                credentials: try AwsCredentials(accessKey: "access", secret: "secret", allocator: allocator),
                expiration: TimeInterval(1000),
                signedBodyHeader: SignedBodyHeaderType.contentSha256,
                signedBodyValue: SignedBodyValue.streamingSha256Payload)

        signingConfig.withCStruct { cSigningConfig in
            XCTAssertEqual(signingConfig.algorithm.rawValue, cSigningConfig.algorithm)
            XCTAssertEqual(signingConfig.signatureType.rawValue, cSigningConfig.signature_type)
            XCTAssertEqual(signingConfig.service, cSigningConfig.service.toString())
            XCTAssertEqual(signingConfig.region, cSigningConfig.region.toString())
            var signingConfigDate = signingConfig.date.toAWSDate()
            var cDate = cSigningConfig.date
            XCTAssertEqual(aws_date_time_diff(&signingConfigDate, &cDate), 0)
            XCTAssertNotNil(cSigningConfig.credentials)
            XCTAssertEqual(UInt64(signingConfig.expiration!), cSigningConfig.expiration_in_seconds)
            XCTAssertEqual(signingConfig.signedBodyHeader.rawValue, cSigningConfig.signed_body_header)
            XCTAssertEqual(signingConfig.signedBodyValue.rawValue, cSigningConfig.signed_body_value.toString())
        }
    }

}
