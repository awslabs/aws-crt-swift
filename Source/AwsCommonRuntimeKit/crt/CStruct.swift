//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCIo
import AwsCCommon

// This file defines the protocols & helper functions for C Structs.
// Instances implementing this protocol should define RawType as their C Struct.
protocol CStruct<RawType> {
    associatedtype RawType
    func withCStruct<Result>(_ body: (RawType) -> Result) -> Result
}

extension CStruct {
    func withCPointer<Result>(_ body: (UnsafePointer<RawType>) -> Result) -> Result {
        return withCStruct { cStruct in
            return withUnsafePointer(to: cStruct) { body($0) }
        }
    }
}

protocol CStructWithShutdownOptions: CStruct {
    func withCStruct<Result>(shutdownOptions: aws_shutdown_callback_options, _ body: (RawType) -> Result) -> Result
}

extension CStructWithShutdownOptions {

    func withCStruct<Result>( _ body: (RawType) -> Result) -> Result {
        withCStruct(shutdownOptions: aws_shutdown_callback_options(), body)
    }

    func withCPointer<Result>(shutdownOptions: aws_shutdown_callback_options, _ body: (UnsafePointer<RawType>) -> Result) -> Result {
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

func withOptionalCStructPointer<Arg1Type, Arg2Type, Arg3Type, Arg4Type, Result>(
        _ arg1: (any CStruct)?,
        _ arg2: (any CStruct)?,
        _ arg3: (any CStruct)?,
        _ arg4: (any CStruct)?,
        _ body: (UnsafePointer<Arg1Type>?,
                 UnsafePointer<Arg2Type>?,
                 UnsafePointer<Arg3Type>?,
                 UnsafePointer<Arg4Type>?) -> Result
) -> Result {
    return withOptionalCStructPointer(to: arg1) { arg1Pointer in
        return withOptionalCStructPointer(to: arg2) { arg2Pointer in
            return withOptionalCStructPointer(to: arg3) { arg3Pointer in
                return withOptionalCStructPointer(to: arg4) { arg4Pointer in
                    return body(arg1Pointer, arg2Pointer, arg3Pointer, arg4Pointer)
                }
            }
        }
    }
}
