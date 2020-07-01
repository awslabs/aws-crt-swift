//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

public enum HttpHeaderBlock {
    case main
    case informational
    case trailing
}

extension HttpHeaderBlock {
    var rawValue: aws_http_header_block {
        switch self {
        case .main: return AWS_HTTP_HEADER_BLOCK_MAIN
        case .informational: return AWS_HTTP_HEADER_BLOCK_INFORMATIONAL
        case .trailing: return AWS_HTTP_HEADER_BLOCK_TRAILING
        }
    }
}

extension aws_http_header_block {
    var headerBlock : HttpHeaderBlock! {
        switch self.rawValue {
        case AWS_HTTP_HEADER_BLOCK_MAIN.rawValue: return HttpHeaderBlock.main
        case AWS_HTTP_HEADER_BLOCK_INFORMATIONAL.rawValue:  return HttpHeaderBlock.informational
        case AWS_HTTP_HEADER_BLOCK_TRAILING.rawValue: return HttpHeaderBlock.trailing
        default:
            assertionFailure("Unknown aws_http_header_block: \(String(describing: self))")
            return nil // <- Makes compiler happy, but we'd have halted right before reaching here
        }
    }
}