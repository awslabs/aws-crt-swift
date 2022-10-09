//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCHttp
public struct HttpHeader {
    public let name: String
    public let value: String
    public let compression: HttpHeaderCompression

    init(name: String,
         value: String,
         compression: HttpHeaderCompression = .useCache,
         allocator: Allocator = defaultAllocator) {
        self.name = name;
        self.value = value;
        self.compression = compression;
    }
}
