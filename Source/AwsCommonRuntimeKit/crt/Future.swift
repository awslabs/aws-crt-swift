//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import Dispatch

public class Future<Value> {
    public typealias FutureResult = Result<Value, Error>
    
    private var _value: FutureResult? {
        get {
            queue.sync { [weak self] in
                guard let strongSelf = self else { return nil }
                return strongSelf._value
            }
        }
        set(value) {
            queue.async(flags: .barrier) { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf._value = value
            }
        }
    }
    
    private let queue = DispatchQueue(label: "atomicValue", qos: .default, attributes: .concurrent)
    
    var waiter = DispatchSemaphore(value: 0)
    
    private var _observers = [((FutureResult) -> Void)]()
    
    public init(value: FutureResult? = nil) {
        self._value = value
    }
    
    public func get() throws -> Value {
        if let value = self._value {
            return try value.get()
        }
        
        waiter.wait()
        //can force unwrap here cuz if wait was lifted, future has completed
        return try self._value!.get()
    }
    
    public func complete(_ value: FutureResult) {
        self._value = value
        self._observers.forEach { $0(value) }
        waiter.signal()
    }
    
    public func then(_ block: @escaping (FutureResult) -> Void) {
        if let value = self._value {
            block(value)
        } else {
            self._observers.append(block)
        }
    }
}

extension Future {
    func chained<T>(closure: @escaping (FutureResult) -> Future<T>) -> Future<T> {
        // We'll start by constructing a "wrapper" promise that will be
        // returned from this method:
        let promise = Future<T>()
        
        // Observe the current future:
        then { result in
            let future = closure(result)
            
            future.then { result in
                promise.complete(result)
            }
        }
        
        return promise
    }
}
