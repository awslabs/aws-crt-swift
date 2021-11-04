//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth

public protocol CRTCredentialsProvider {
    var allocator: Allocator {get set}
    func getCredentials() async throws -> CRTCredentials

}
