//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit

class FutureTests: XCTestCase {

    func testFuture() throws {
        let future = Future<String>(value: .success("test"))
        let expectation = XCTestExpectation(description: "then succeeded")
        future.then { result in
            XCTAssertEqual("test", try! result.get())
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func testFutureVoid() throws {
        let future = Future<Void>(value: .success(()))
        let expectation = XCTestExpectation(description: "then succeeded")
        future.then { _ in

            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }
}
