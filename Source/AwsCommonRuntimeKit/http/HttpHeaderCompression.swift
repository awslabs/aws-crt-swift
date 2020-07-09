//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import Foundation
import AwsCHttp

public enum HttpHeaderCompression {
    /**
     * Compress header by encoding the cached index of its strings,
     * or by updating the cache to contain these strings for future reference.
     * Best for headers that are sent repeatedly.
     * This is the default setting.
     */
    case useCache
    /**
     * Encode header strings literally.
     * If an intermediary re-broadcasts the headers, it is permitted to use cache.
     * Best for unique headers that are unlikely to repeat.
     */
    case noCache
    
    /**
     * Encode header strings literally and forbid all intermediaries from using
     * cache when re-broadcasting.
     * Best for header fields that are highly valuable or sensitive to recovery.
     */
    case noForwardCache
}

extension HttpHeaderCompression {
    var rawValue: aws_http_header_compression {
        switch self {
        case .useCache: return AWS_HTTP_HEADER_COMPRESSION_USE_CACHE
        case .noCache: return AWS_HTTP_HEADER_COMPRESSION_NO_CACHE
        case .noForwardCache: return AWS_HTTP_HEADER_COMPRESSION_NO_FORWARD_CACHE
        }
    }
}

extension aws_http_header_compression {
    var headerCompression : HttpHeaderCompression? {
        switch self.rawValue {
        case AWS_HTTP_HEADER_COMPRESSION_USE_CACHE.rawValue: return HttpHeaderCompression.useCache
        case AWS_HTTP_HEADER_COMPRESSION_NO_CACHE.rawValue:  return HttpHeaderCompression.noCache
        case AWS_HTTP_HEADER_COMPRESSION_NO_FORWARD_CACHE.rawValue: return HttpHeaderCompression.noForwardCache
        default:
            assertionFailure("Unknown aws_http_header_compression: \(String(describing: self))")
            return nil
        }
    }
}

