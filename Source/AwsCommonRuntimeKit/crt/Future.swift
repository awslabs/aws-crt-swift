//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import Foundation

public class Future<Value> {
    public typealias FutureResult = Result<Value, Error>
   
    var _value: FutureResult?
    
    var waiter = DispatchSemaphore(value: 0)
    
    private var _observers = [((FutureResult) -> Void)]()
    
    public init(value: FutureResult? = nil) {
        self._value = value
        
    }
    
    public func get() throws -> Value? {
        waiter.wait()
        if let value = self._value {
            return try value.get()
        }
        
        return nil
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
