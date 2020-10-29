//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import Foundation

public final class Future<Value> {
    public typealias FutureResult = Result<Value, Error>
    
    private var _value: FutureResult? //nil when pending
    
    private var waiter = DispatchSemaphore(value: 0)
    
    private var _observers: [((FutureResult) -> Void)] = []
    
    public init(value: FutureResult? = nil) {
        self._value = value
    }
    
    public func get() throws -> Value? {
        switch _value {
        // Throw/return the result immediately if available.
        case .failure(let error):
          throw error
        case .success(let value):
          return value
        // Wait for the future if no result has been fulfilled.
        case nil:
            waiter.wait()
        }
        return nil
    }
    
    public func fulfill(_ value: Value) {
        precondition(self._value == nil, "can only be fulfilled once")
        let result = FutureResult.success(value)
        self._value = result
        _observers.forEach { $0(result) }
        _observers = []
    }
    
    public func fail(_ error: Error) {
        precondition(self._value == nil, "can only be fulfilled once")
        let result = FutureResult.failure(error)
        self._value = result
        _observers.forEach { $0(result) }
        _observers = []
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
                switch result {
                case .failure(let error):
                    promise.fail(error)
                case .success(let value):
                    promise.fulfill(value)
                }
            }
        }
        
        return promise
    }
}
