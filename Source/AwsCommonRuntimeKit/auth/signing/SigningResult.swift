//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCAuth

public struct SigningResult {
    let rawValue: UnsafeMutablePointer<aws_signing_result>?

    public init?(rawValue: UnsafeMutablePointer<aws_signing_result>?) {
        self.rawValue = rawValue
    }
}
