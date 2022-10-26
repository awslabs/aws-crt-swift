//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCIo
import AwsCCommon

protocol CStruct<cStructType> {
    associatedtype cStructType
    func withCStruct<Result>(_ body: (cStructType) -> Result) -> Result
}

extension CStruct {
    func withCPointer<Result>(_ body: (UnsafePointer<cStructType>) -> Result) -> Result {
        return withCStruct { cStruct in
            return withUnsafePointer(to: cStruct) { body($0) }
        }
    }
}

protocol CStructWithShutdownOptions: CStruct {
    associatedtype cStructType
    func withCStruct<Result>(shutdownOptions: aws_shutdown_callback_options, _ body: (cStructType) -> Result) -> Result
}

extension CStructWithShutdownOptions {

    func withCStruct<Result>( _ body: (cStructType) -> Result) -> Result {
        withCStruct(shutdownOptions: aws_shutdown_callback_options(), body)
    }

    func withCPointer<Result>(shutdownOptions: aws_shutdown_callback_options, _ body: (UnsafePointer<cStructType>) -> Result) -> Result {
        return withCStruct(shutdownOptions: shutdownOptions) { cStruct in
            return withUnsafePointer(to: cStruct) { body($0) }
        }
    }
}

func withOptionalCStructPointer<T, Result>(
        to arg1: (any CStruct)?, _ body: (UnsafePointer<T>?) -> Result
) -> Result {
    if let arg1 = arg1 {
        return arg1.withCStruct { cStruct in
            return withUnsafePointer(to: cStruct as! T) { structPointer in
                body(structPointer)
            }
        }
    }
    return body(nil)
}

