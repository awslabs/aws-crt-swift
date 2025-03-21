//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCIo
import AwsCCommon

// This file defines the protocols & helper functions for C Structs.
// Instances implementing this protocol should define RawType as their C Struct.

protocol CStruct {
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

extension Array where Element: CStruct {
    /// Convert a CStruct Array into raw c pointer. The function would not do a deep copy of the CStruct element. If you required a deep copy
    /// make sure to clean up the memory underneath. 
    func withAWSArrayList<Result>(_ body: (OpaquePointer?) throws -> Result) rethrows -> Result {
        guard capacity != 0 else {
            return try body(nil)
        }
        
        let array_list: UnsafeMutablePointer<aws_array_list> = allocator.allocate(capacity: 1)
        defer {
            aws_array_list_clean_up(array_list)
            allocator.release(array_list)
        }
        guard aws_array_list_init_dynamic(
            array_list,
            allocator.rawValue,
            count,
            MemoryLayout<Element.RawType>.size) == AWS_OP_SUCCESS else {
            fatalError("Unable to initialize array of user properties")
        }
        forEach {
            $0.withCPointer {
                // `aws_array_list_push_back` will do a memory copy of $0 into array_list, but it would
                // not do a deep copy there.
                guard aws_array_list_push_back(array_list, $0) == AWS_OP_SUCCESS else {
                    fatalError("Unable to add user property")
                }
            }
        }
        return try body(OpaquePointer(array_list.pointee.data))
    }
}

protocol CStructWithShutdownOptions: CStruct {
    func withCStruct<Result>(shutdownOptions: aws_shutdown_callback_options, _ body: (RawType) -> Result) -> Result
}

extension CStructWithShutdownOptions {

    func withCStruct<Result>( _ body: (RawType) -> Result) -> Result {
        withCStruct(shutdownOptions: aws_shutdown_callback_options(), body)
    }

    func withCPointer<Result>(
        shutdownOptions: aws_shutdown_callback_options,
        _ body: (UnsafePointer<RawType>) -> Result) -> Result {
        return withCStruct(shutdownOptions: shutdownOptions) { cStruct in
            return withUnsafePointer(to: cStruct) { body($0) }
        }
    }
}

protocol CStructWithUserData: CStruct {
    func withCStruct<Result>(
        userData: UnsafeMutableRawPointer?,
        _ body: (RawType) -> Result) -> Result
}

extension CStructWithUserData {

    func withCStruct<Result>(_ body: (RawType) -> Result) -> Result {
        withCStruct(userData: nil, body)
    }

    func withCPointer<Result>(
        userData: UnsafeMutableRawPointer?,
        _ body: (UnsafePointer<RawType>) -> Result) -> Result {
        return withCStruct(userData: userData) { cStruct in
            return withUnsafePointer(to: cStruct) { body($0) }
        }
    }
}

func withOptionalCStructPointer<T: CStruct, Result>(
    to arg1: T?, _ body: (UnsafePointer<T.RawType>?) -> Result
) -> Result {
    if let arg1 = arg1 {
        return arg1.withCStruct { cStruct in
            return withUnsafePointer(to: cStruct) { structPointer in
                body(structPointer)
            }
        }
    }
    return body(nil)
}

func withOptionalCStructPointer<Arg1Type: CStruct,
                                Arg2Type: CStruct,
                                Result>(
    _ arg1: Arg1Type?,
    _ arg2: Arg2Type?,
    _ body: (UnsafePointer<Arg1Type.RawType>?,
             UnsafePointer<Arg2Type.RawType>?) -> Result
) -> Result {
    return withOptionalCStructPointer(to: arg1) { arg1Pointer in
        return withOptionalCStructPointer(to: arg2) { arg2Pointer in
            return body(arg1Pointer, arg2Pointer)
        }
    }
}

func withOptionalCStructPointer<Arg1Type: CStruct,
                                Arg2Type: CStruct,
                                Arg3Type: CStruct,
                                Arg4Type: CStruct,
                                Arg5Type: CStruct,
                                Result>(
    _ arg1: Arg1Type?,
    _ arg2: Arg2Type?,
    _ arg3: Arg3Type?,
    _ arg4: Arg4Type?,
    _ arg5: Arg5Type?,
    _ body: (UnsafePointer<Arg1Type.RawType>?,
             UnsafePointer<Arg2Type.RawType>?,
             UnsafePointer<Arg3Type.RawType>?,
             UnsafePointer<Arg4Type.RawType>?,
             UnsafePointer<Arg5Type.RawType>?) -> Result
) -> Result {
    return withOptionalCStructPointer(arg1, arg2) { arg1Pointer, arg2Pointer in
        return withOptionalCStructPointer(arg3, arg4) { arg3Pointer, arg4Pointer in
            return withOptionalCStructPointer(to: arg5) { arg5Pointer in
                return body(
                    arg1Pointer,
                    arg2Pointer,
                    arg3Pointer,
                    arg4Pointer,
                    arg5Pointer)
            }
        }
    }
}

func withOptionalCStructPointer<Arg1Type: CStruct,
                                Arg2Type: CStruct,
                                Arg3Type: CStruct,
                                Arg4Type: CStruct,
                                Arg5Type: CStruct,
                                Arg6Type: CStruct,
                                Result>(
    _ arg1: Arg1Type?,
    _ arg2: Arg2Type?,
    _ arg3: Arg3Type?,
    _ arg4: Arg4Type?,
    _ arg5: Arg5Type?,
    _ arg6: Arg6Type?,
    _ body: (UnsafePointer<Arg1Type.RawType>?,
             UnsafePointer<Arg2Type.RawType>?,
             UnsafePointer<Arg3Type.RawType>?,
             UnsafePointer<Arg4Type.RawType>?,
             UnsafePointer<Arg5Type.RawType>?,
             UnsafePointer<Arg6Type.RawType>?) -> Result
) -> Result {
    return withOptionalCStructPointer(arg1, arg2) { arg1Pointer, arg2Pointer in
        return withOptionalCStructPointer(arg3, arg4) { arg3Pointer, arg4Pointer in
            return withOptionalCStructPointer(arg5, arg6) { arg5Pointer, arg6Pointer in
                return body(
                    arg1Pointer,
                    arg2Pointer,
                    arg3Pointer,
                    arg4Pointer,
                    arg5Pointer,
                    arg6Pointer)
            }
        }
    }
}
