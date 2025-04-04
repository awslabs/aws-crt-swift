// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

#ifndef SWIFT_COMMON_RUNTIME_ERROR_H
#define SWIFT_COMMON_RUNTIME_ERROR_H
#include <aws/common/common.h>
#include <aws/common/error.h>

/**
 * The file introduced the swift error spaces, defines the error code used for aws-crt-swift.
 * We defined the error codes here because Swift error handling requires the use of enums, and Swift
 * does not support extensible enums, which makes future extensions challenging. Therefore, we chose
 * to add a C error space to ensure future-proofing.
 */

#define AWS_CRT_SWIFT_PACKAGE_ID 17

#define AWS_DEFINE_ERROR_INFO_CRT_SWIFT(CODE, STR) [(CODE)-0x4400] = AWS_DEFINE_ERROR_INFO(CODE, STR, "aws-crt-swift")

enum aws_swift_errors {
    AWS_CRT_SWIFT_MQTT_CLIENT_CLOSED = AWS_ERROR_ENUM_BEGIN_RANGE(AWS_CRT_SWIFT_PACKAGE_ID),
    AWS_CRT_SWIFT_ERROR_END_RANGE = AWS_ERROR_ENUM_END_RANGE(AWS_CRT_SWIFT_PACKAGE_ID),
};


static const struct aws_error_info s_crt_swift_errors[] = {
    AWS_DEFINE_ERROR_INFO_CRT_SWIFT(
                                    AWS_CRT_SWIFT_MQTT_CLIENT_CLOSED,
                                    "The Mqtt Client is closed.")
};

static const struct aws_error_info_list s_crt_swift_error_list = {
    .error_list = s_crt_swift_errors,
    .count = AWS_ARRAY_SIZE(s_crt_swift_errors),
};

#endif /* SWIFT_COMMON_RUNTIME_ERROR_H */
