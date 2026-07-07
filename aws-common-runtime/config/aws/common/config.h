/**
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

#ifndef AWS_COMMON_CONFIG_H
#define AWS_COMMON_CONFIG_H

/*
 * This header exposes compiler feature test results determined during cmake
 * configure time to inline function implementations. The macros defined here
 * should be considered to be an implementation detail, and can change at any
 * time.
 */
#if defined(__APPLE__) && !defined(__ANDROID__)
/* This is a trick to skip OpenSSL header on Apple platforms since Swift Package Manager is not smart enough to exclude
 * some headers.
 */
#    define AWS_C_CAL_OPENSSLCRYPTO_COMMON_H
#endif

#define AWS_UNSTABLE_TESTING_API 1
#define AWS_AFFINITY_METHOD 0

/* Android doesn't have execinfo.h (backtrace functions) */
#if !defined(__ANDROID__)
#    define AWS_HAVE_EXECINFO 1
#endif

#endif
