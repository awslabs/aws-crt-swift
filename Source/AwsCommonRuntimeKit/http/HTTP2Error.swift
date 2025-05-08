//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

/// Error codes that may be present in HTTP/2 RST_STREAM and GOAWAY frames (RFC-7540 7).
public enum HTTP2Error: UInt32 {
  case protocolError = 1
  case internalError = 2
  case flowControlError = 3
  case settingsTimeout = 4
  case streamClosed = 5
  case frameSizeError = 6
  case refusedStream = 7
  case cancel = 8
  case compressionError = 9
  case connectError = 10
  case enhanceYourCalm = 11
  case inadequateSecurity = 12
  case HTTP_1_1_Required = 13
}
