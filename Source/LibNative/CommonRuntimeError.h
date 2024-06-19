// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

#ifndef SWIFT_COMMON_RUNTIME_ERROR_H
#define SWIFT_COMMON_RUNTIME_ERROR_H
#include <aws/common/common.h>
#include <aws/common/error.h>

#define AWS_CRT_SWIFT_PACKAGE_ID 17

#define AWS_DEFINE_ERROR_INFO_CRT_SWIFT(CODE, STR) [(CODE)-0x4400] = AWS_DEFINE_ERROR_INFO(CODE, STR, "aws-crt-swift")

enum aws_swift_errors {
    AWS_CRT_SWIFT_INVALID_ARGUMENT = AWS_ERROR_ENUM_BEGIN_RANGE(AWS_CRT_SWIFT_PACKAGE_ID),
    AWS_CRT_SWIFT_MQTT_CLIENT_CLOSED,
    AWS_CRT_SWIFT_ERROR_END_RANGE = AWS_ERROR_ENUM_END_RANGE(AWS_CRT_SWIFT_PACKAGE_ID),
};


static struct aws_error_info s_crt_swift_errors[] = {
    AWS_DEFINE_ERROR_INFO_CRT_SWIFT(
                                    AWS_CRT_SWIFT_INVALID_ARGUMENT,
                                    "An invalid argument was passed to a function."),
    AWS_DEFINE_ERROR_INFO_CRT_SWIFT(
                                    AWS_CRT_SWIFT_MQTT_CLIENT_CLOSED,
                                    "The Mqtt Client is closed.")
};

static struct aws_error_info_list s_crt_swift_error_list = {
    .error_list = s_crt_swift_errors,
    .count = AWS_ARRAY_SIZE(s_crt_swift_errors),
};

#endif /* SWIFT_COMMON_RUNTIME_ERROR_H */
