//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

private class Executor {
    var callTrace: [Int] = []
    var callNumber = 0

    func executeAsyncOperation(completion: @escaping () -> Void) {
        DispatchQueue.global().async {
            self.callNumber += 1
            self.callTrace.append(self.callNumber)
            completion()
        }
    }
}

class BlockingExecutor_Tests: XCTestCase {
    private var executor: BlockingExecutor!

    override func setUp() {
        executor = BlockingExecutor(executorTitle: "BlockingExecutorTests")
        super.setUp()
    }

    override func tearDown() {
        executor = nil
        super.tearDown()
    }

    func testSameErrorIsPassedFromExecutorBlock() {
        let error = NSError(domain: "tests", code: 123)

        executor.executeBlocking(executor: { executorCompletion in
            executorCompletion(error)
        }, completion: { completionError in
            XCTAssertNotNil(completionError)
            XCTAssertEqual(completionError as? NSError, error)
        })
    }
//
//    func testSemaphoreUnlockedAfterExecutorCalledCompletion() {
//
//    }
//
//    func testDifferentEntitiesHasDifferentQueueLabel() {
////        let suffix = "QueuedExecutorTests"
////        let executor1 = QueuedExecutor(queueLabelSuffix: suffix)
////        let executor2 = QueuedExecutor(queueLabelSuffix: suffix)
////
////        executor1.executeInQueue(executor: <#T##@escaping ExecutorClosure##@escaping StreamChat.QueuedExecutor.ExecutorClosure#>) { error in
////
////        }
//    }
//
//    func testQueueWaitsForAsyncOperation() {
////        executor.executeInQueue(executor: { executorCompletion in
////
////        }, completion: { error in
////
////        })
//    }
//
//    func testDifferentMultipleJobsPostedInQueue() {
//
//    }
}
