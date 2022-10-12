//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
import Foundation
@testable import AwsCommonRuntimeKit

class CRTAWSEndpointsRuleEngineTests: CrtXCBaseTestCase {

    let partitions = #"""
    {
      "version": "1.1",
      "partitions": [
        {
          "id": "aws",
          "regionRegex": "^(us|eu|ap|sa|ca|me|af)-\\w+-\\d+$",
          "regions": {
            "af-south-1": {},
            "af-east-1": {},
            "ap-northeast-1": {},
            "ap-northeast-2": {},
            "ap-northeast-3": {},
            "ap-south-1": {},
            "ap-southeast-1": {},
            "ap-southeast-2": {},
            "ap-southeast-3": {},
            "ca-central-1": {},
            "eu-central-1": {},
            "eu-north-1": {},
            "eu-south-1": {},
            "eu-west-1": {},
            "eu-west-2": {},
            "eu-west-3": {},
            "me-south-1": {},
            "sa-east-1": {},
            "us-east-1": {},
            "us-east-2": {},
            "us-west-1": {},
            "us-west-2": {},
            "aws-global": {}
          },
          "outputs": {
            "name": "aws",
            "dnsSuffix": "amazonaws.com",
            "dualStackDnsSuffix": "api.aws",
            "supportsFIPS": true,
            "supportsDualStack": true
          }
        },
        {
          "id": "aws-us-gov",
          "regionRegex": "^us\\-gov\\-\\w+\\-\\d+$",
          "regions": {
            "us-gov-west-1": {},
            "us-gov-east-1": {},
            "aws-us-gov-global": {}
          },
          "outputs": {
            "name": "aws-us-gov",
            "dnsSuffix": "amazonaws.com",
            "dualStackDnsSuffix": "api.aws",
            "supportsFIPS": true,
            "supportsDualStack": true
          }
        },
        {
          "id": "aws-cn",
          "regionRegex": "^cn\\-\\w+\\-\\d+$",
          "regions": {
            "cn-north-1": {},
            "cn-northwest-1": {},
            "aws-cn-global": {}
          },
          "outputs": {
            "name": "aws-cn",
            "dnsSuffix": "amazonaws.com.cn",
            "dualStackDnsSuffix": "api.amazonwebservices.com.cn",
            "supportsFIPS": true,
            "supportsDualStack": true
          }
        },
        {
          "id": "aws-iso",
          "regionRegex": "^us\\-iso\\-\\w+\\-\\d+$",
          "outputs": {
            "name": "aws-iso",
            "dnsSuffix": "c2s.ic.gov",
            "supportsFIPS": true,
            "supportsDualStack": false,
            "dualStackDnsSuffix": "c2s.ic.gov"
          },
          "regions": {
            "aws-iso-global": {}
          }
        },
        {
          "id": "aws-iso-b",
          "regionRegex": "^us\\-isob\\-\\w+\\-\\d+$",
          "outputs": {
            "name": "aws-iso-b",
            "dnsSuffix": "sc2s.sgov.gov",
            "supportsFIPS": true,
            "supportsDualStack": false,
            "dualStackDnsSuffix": "sc2s.sgov.gov"
          },
          "regions": {
            "aws-iso-b-global": {}
          }
        }
      ]
    }
    """#
    
    let ruleSet = #"""
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
        """#
    
    func testResolve() throws {
        let engine = try CRTAWSEndpointsRuleEngine(partitions: partitions, ruleSet: ruleSet)
        let context = try CRTAWSEndpointsRequestContext()
        try context.add(name: "Region", value: "us-west-2")
        let endpoint = try engine.resolve(context: context)
        let url = try endpoint?.getURL()
        XCTAssertNotNil(url)
        XCTAssertEqual("https://example.us-west-2.amazonaws.com", url!)
    }
    
    func testRuleSetParsingPerformance() {
        measure {
            _ = try! CRTAWSEndpointsRuleEngine(partitions: partitions, ruleSet: ruleSet)
        }
    }
    
    func testRuleSetEvaluationPerformance() {
        let engine = try! CRTAWSEndpointsRuleEngine(partitions: partitions, ruleSet: ruleSet)
        let context = try! CRTAWSEndpointsRequestContext()
        try! context.add(name: "Region", value: "us-west-2")
        measure {
            let _ = try! engine.resolve(context: context)
        }
    }
    
    func testResolvePerformance() {
        measure {
            let engine = try! CRTAWSEndpointsRuleEngine(partitions: partitions, ruleSet: ruleSet)
            let context = try! CRTAWSEndpointsRequestContext()
            try! context.add(name: "Region", value: "us-west-2")
            let _ = try! engine.resolve(context: context)
        }
    }
}
