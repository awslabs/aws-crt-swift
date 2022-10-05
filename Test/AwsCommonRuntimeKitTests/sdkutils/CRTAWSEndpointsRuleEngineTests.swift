//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
import Foundation
@testable import AwsCommonRuntimeKit

class CRTAWSEndpointsRuleEngineTests: CrtXCBaseTestCase {
    let ruleSetString =
        """
        {
          "version": "1.0",
          "serviceId": "example",
          "parameters": {
            "Region": {
              "type": "string",
              "builtIn": "AWS::Region",
              "documentation": "The region to dispatch the request to"
            }
          },
          "rules": [
            {
              "documentation": "rules for when region isSet",
              "type": "tree",
              "conditions": [
                {
                  "fn": "isSet",
                  "argv": [
                    {
                      "ref": "Region"
                    }
                  ]
                }
              ],
              "rules": [
                {
                  "type": "endpoint",
                  "conditions": [
                    {
                      "fn": "aws.partition",
                      "argv": [
                        {
                          "ref": "Region"
                        }
                      ],
                      "assign": "partitionResult"
                    }
                  ],
                  "endpoint": {
                    "url": "https://example.{Region}.{partitionResult#dnsSuffix}"
                  }
                },
                {
                  "type": "error",
                  "documentation": "invalid region value",
                  "conditions": [],
                  "error": "unable to determine endpoint for region: {Region}"
                }
              ]
            },
            {
              "type": "endpoint",
              "documentation": "the single service global endpoint",
              "conditions": [],
              "endpoint": {
                "url": "https://example.amazonaws.com"
              }
            }
          ]
        }
        """
    
    func testResolve() throws {
        let engine = try CRTAWSEndpointsRuleEngine(ruleSetString: ruleSetString)
        let context = try CRTAWSEndpointsRequestContext()
        try context.add(name: "Region", value: "us-west-2")
        let endpoint = try engine.resolve(context: context)
        let url = try endpoint?.getURL()
        XCTAssertNotNil(url)
        XCTAssertEqual("https://example.us-west-2.amazonaws.com", url!)
    }
}
