//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

public enum SignedBodyValue: String {
    /// if string is empty  a public value  will be calculated from the payload during signing
    case empty = ""
    case emptySha256 = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
    /// Use this in the case of needing to not use the payload for signing
    case unsignedPayload = "UNSIGNED-PAYLOAD"
    case streamingSha256Payload = "STREAMING-AWS4-HMAC-SHA256-PAYLOAD"
    case streamingSha256Events = "STREAMING-AWS4-HMAC-SHA256-EVENTS"
}
