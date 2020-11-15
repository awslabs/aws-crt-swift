//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import Foundation

public final class Future<Value> {
    public typealias FutureResult = Result<Value, Error>

    private var _value: FutureResult? //nil when pending

    private var waiter = DispatchSemaphore(value: 0)

    private var _observers: [((FutureResult) -> Void)] = []
    
    private let lock = NSLock()

    public init(value: FutureResult? = nil) {
        self._value = value
    }
    
    public func get() throws -> Value {
        lock.lock()
        if let value = self._value {
            lock.unlock()
            return try value.get()
        }

        waiter.wait()
        defer { lock.unlock() }
        //can force unwrap here cuz if wait was lifted, future has completed
        return try self._value!.get()
    }

    public func fulfill(_ value: Value) {
        lock.lock()
        guard self._value == nil else {
            return lock.unlock() //already resolved
        }
        let result = FutureResult.success(value)
        self._value = result
        let observers = _observers
        _observers = []
        lock.unlock()
        observers.forEach { $0(result) }
        waiter.signal()
    }

    public func fail(_ error: Error) {
        lock.lock()
        guard self._value == nil else {
            return lock.unlock()
        }
        let result = FutureResult.failure(error)
        self._value = result
        let observers = _observers
        _observers = []
        lock.unlock()
        observers.forEach { $0(result) }
        waiter.signal()
    }

    public func then(_ block: @escaping (FutureResult) -> Void) {
        lock.lock()
        guard let value = self._value else {
            self._observers.append(block)
            return lock.unlock() //still pending, handlers attached
        }
        lock.unlock()
        block(value)
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
