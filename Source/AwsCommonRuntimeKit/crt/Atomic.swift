//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCCommon

struct Atomic<I> {
    let pointer: UnsafeMutableRawPointer
    let rawValue: aws_atomic_var
    init(_ type: I) {
        let pointer: UnsafeMutableRawPointer = fromPointer(ptr: type)
        rawValue = aws_atomic_var(value: pointer)
        self.pointer = pointer
    }
}
