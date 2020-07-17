//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCHttp

public enum HttpHeaderBlock {
    case main
    case informational
    case trailing
}

extension HttpHeaderBlock: RawRepresentable, CaseIterable {
    public static var allCases: [HttpHeaderBlock] {
        return [.main, .informational, .trailing]
    }
    
    public init(rawValue: aws_http_header_block) {
        let value = Self.allCases.first(where: {$0.rawValue == rawValue})
        self = value ?? .main
    }
    
    public var rawValue: aws_http_header_block {
        switch self {
        case .main: return AWS_HTTP_HEADER_BLOCK_MAIN
        case .informational: return AWS_HTTP_HEADER_BLOCK_INFORMATIONAL
        case .trailing: return AWS_HTTP_HEADER_BLOCK_TRAILING
        }
    }
}

