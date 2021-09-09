////
//// Copyright © 2021 Stream.io Inc. All rights reserved.
////
//
//import Foundation
//@testable import StreamChat
//import XCTest
//
//private class Executor {
//    var callTrace: [Int] = []
//    var callNumber = 0
//
//    func executeAsyncOperation(completion: () -> Void) {
//        DispatchQueue.global().async {
//            self.callNumber += 1
//            self.callTrace.append(self.callNumber)
//            completion()
//        }
//    }
//}
//
//extension NSError: Equatable {
//    public static func ==(lhs: NSError, rhs: NSError) -> Bool {
//        return lhs.code == rhs.code
//            && lhs.domain == rhs.domain
//            && rhs.userInfo == lhs.userInfo
//    }
//}
//
//class QueuedExecutor_Tests: XCTestCase {
//    private var executor: QueuedExecutor!
//
//    override func setUp() {
//        super.setUp()
//    }
//
//    override func tearDown() {
//        super.tearDown()
//    }
//
//    func testSameErrorIsPassedFromExecutorBlock() {
//        let error = NSError(domain: "tests", code: 123)
//
//        executor.executeInQueue(executor: { executorCompletion in
//            executorCompletion(error)
//        }, completion: { completionError in
//            XCTAssertEqual(completionError, error)
//        })
//    }
//
//    func testSemaphoreUnlockedAfterExecutorCalledCompletion() {
//
//    }
//
//    func testDifferentEntitiesHasDifferentQueueLabel() {
//        let suffix = "QueuedExecutorTests"
//        let executor1 = QueuedExecutor(queueLabelSuffix: suffix)
//        let executor2 = QueuedExecutor(queueLabelSuffix: suffix)
//
//        executor1.executeInQueue(executor: <#T##@escaping ExecutorClosure##@escaping StreamChat.QueuedExecutor.ExecutorClosure#>) { error in
//
//        }
//    }
//
//    func testQueueWaitsForAsyncOperation() {
//        executor.executeInQueue(executor: { executorCompletion in
//
//        }, completion: { error in
//
//        })
//    }
//
//    func testDifferentMultipleJobsPostedInQueue() {
//
//    }
//}
