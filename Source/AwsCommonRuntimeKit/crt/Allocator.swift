//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCCommon

/**
 The default allocator.
 You are probably looking to use `allocator` instead.
 */
public let defaultAllocator = aws_default_allocator()!

/// An allocator is used to allocate memory on the heap.
public protocol Allocator {

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
public final class TracingAllocator: Allocator {
    public let rawValue: UnsafeMutablePointer<aws_allocator>

    /**
     Creates an `Allocator` that doesn't track anything.

     - Parameter allocator: The allocator to be traced.
     */
    public convenience init(_ allocator: Allocator = defaultAllocator) {
        self.init(allocator, level: .none, framesPerStack: 0)
    }

    /**
     * Creates an `Allocator` that counts allocated bytes and total allocation.
     *
     * - Parameter allocator: The allocator to be traced.
     */
    public convenience init(tracingBytesOf allocator: Allocator) {
        self.init(allocator, level: .bytes, framesPerStack: 0)
    }

    /**
     * Creates an `Allocator` that captures stack traces of all allocations.
     *
     * - Parameter allocator: The allocator to be traced.
     * - Parameter framesPerStack: How many frames to record for each allocation
     *   (8 as usually a good default to start with).
     */
    public convenience init(tracingStacksOf allocator: Allocator, framesPerStack: Int = 10) {
        self.init(allocator, level: .stacks, framesPerStack: framesPerStack)
    }

    private init(_ allocator: Allocator, level: TracingLevel, framesPerStack: Int) {
        self.rawValue = aws_mem_tracer_new(allocator.rawValue, nil, aws_mem_trace_level(level.rawValue), framesPerStack)
    }

    deinit {
        aws_mem_tracer_destroy(self.rawValue)
    }

    /// The current number of bytes in outstanding allocations.
    public var bytes: Int {
        return aws_mem_tracer_bytes(self.rawValue)
    }

    /// The current number of outstanding allocations.
    public var count: Int {
        return aws_mem_tracer_count(self.rawValue)
    }

    /**
     If there are outstanding allocations, dumps them to log, along with any
     information gathered based on the trace level set when this instance was
     created.
     */
    public func dump() {
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
    public var rawValue: UnsafeMutablePointer<Pointee> { return self }
}
