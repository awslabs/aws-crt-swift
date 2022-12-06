//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCSdkUtils

/// Resolved endpoint type
public enum ResolvedEndpoint {
    /// Used for endpoints that are resolved successfully
    case endpoint(url: String, headers: [String: [String]], properties: [String: AnyHashable])

    /// Used for endpoints that resolve to an error
    case error(message: String)
}
