//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCCommon

/*
 * The default allocator.
 * We need to declare `allocator` as mutable (`var`) instead of `let` because we override it with a tracing allocator in tests. This is not mutated anywhere else apart from the start of tests.
 * Swift compiler doesn't let us compile this code in Swift 6 due to global shared mutable state without locks, and complains that this is not safe. Disable the safety here since we won't modify it.
 * Remove the Ifdef once our minimum supported Swift version reaches 5.10
 */
#if swift(>=5.10)
nonisolated(unsafe) var allocator = aws_default_allocator()!
#else
var allocator = aws_default_allocator()!
#endif

/// An allocator is used to allocate memory on the heap.
protocol Allocator {

    /// The raw `aws_allocator` pointer.
    var rawValue: UnsafeMutablePointer<aws_allocator> { get }
}

internal extension Allocator {
    /**
     * Allocates memory on the heap.
     *
     * - Parameter <T>: The type that the allocated memory is supposed to hold
     * - Parameter capacity: How many instances of `<T>` to allocate for.
     *
     * - Returns: The allocated memory
     * - Throws AwsError.memoryAllocationFailure: If the allocation failed.
     */
    func allocate<T>(capacity: Int) -> UnsafeMutablePointer<T> {
        guard let result = aws_mem_calloc(self.rawValue, capacity, MemoryLayout<T>.size) else {
            fatalError("Failed to allocate memory.")
        }
        return result.bindMemory(to: T.self, capacity: capacity)
    }

    /**
     * Releases memory allocated by this allocator.
     *
     * - Parameter pointer: The pointer to allocated data.
     */
    func release<T>(_ pointer: UnsafeMutablePointer<T>?) {
        return aws_mem_release(self.rawValue, pointer)
    }
}

/// An `Allocator` that traces memory allocations.
final class TracingAllocator: Allocator {
    let rawValue: UnsafeMutablePointer<aws_allocator>

    /**
     Creates an `Allocator` that doesn't track anything.

     - Parameter allocator: The allocator to be traced.
     */
    convenience init(_ allocator: Allocator) {
        self.init(allocator, level: .none, framesPerStack: 0)
    }

    /**
     * Creates an `Allocator` that counts allocated bytes and total allocation.
     *
     * - Parameter allocator: The allocator to be traced.
     */
    convenience init(tracingBytesOf allocator: Allocator) {
        self.init(allocator, level: .bytes, framesPerStack: 0)
    }

    /**
     * Creates an `Allocator` that captures stack traces of all allocations.
     *
     * - Parameter allocator: The allocator to be traced.
     * - Parameter framesPerStack: How many frames to record for each allocation
     *   (8 as usually a good default to start with).
     */
    convenience init(tracingStacksOf allocator: Allocator, framesPerStack: Int = 10) {
        self.init(allocator, level: .stacks, framesPerStack: framesPerStack)
    }

    private init(_ tracingAllocator: Allocator, level: TracingLevel, framesPerStack: Int) {
        self.rawValue = aws_mem_tracer_new(
            tracingAllocator.rawValue,
            nil,
            aws_mem_trace_level(level.rawValue),
            framesPerStack)
    }

    deinit {
        aws_mem_tracer_destroy(self.rawValue)
    }

    /// The current number of bytes in outstanding allocations.
    var bytes: Int {
        return aws_mem_tracer_bytes(self.rawValue)
    }

    /// The current number of outstanding allocations.
    var count: Int {
        return aws_mem_tracer_count(self.rawValue)
    }

    /**
     If there are outstanding allocations, dumps them to log, along with any
     information gathered based on the trace level set when this instance was
     created.
     */
    func dump() {
        aws_mem_tracer_dump(self.rawValue)
    }

    private enum TracingLevel: UInt32 {
        /// No tracing
        case none = 0
        /// Tracking allocation sizes and total allocated size
        case bytes = 1
        /// Capture all stack traces for allocations
        case stacks = 2
    }
}

extension UnsafeMutablePointer: Allocator where Pointee == aws_allocator {
    @inlinable
    var rawValue: UnsafeMutablePointer<Pointee> { return self }
}
