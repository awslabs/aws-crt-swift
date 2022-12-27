//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp

public enum HTTPVersion {
        case unknown // Invalid version
        case version_1_0
        case version_1_1
        case version_2
};

extension HTTPVersion: RawRepresentable, CaseIterable {

    public init(rawValue: aws_http_version) {
        let value = Self.allCases.first(where: {$0.rawValue == rawValue})
        self = value ?? .unknown
    }
    public var rawValue: aws_http_version {
        switch self {
        case .unknown:  return AWS_HTTP_VERSION_UNKNOWN
        case .version_1_0: return AWS_HTTP_VERSION_1_0
        case .version_1_1: return AWS_HTTP_VERSION_1_1
        case .version_2: return AWS_HTTP_VERSION_2
        }
    }
}
