//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

private struct QueuedExecutorIdentifier {
    static var identifier = 0
}

class QueuedExecutor {
    typealias Completion = (Error?) -> Void
    typealias ExecutorClosure = (_: @escaping Completion) -> Void

    // Serial Synchronisation Queue
    // Needed to set requests to queue and load one-by-one and not in parallel
    private let syncQueue: DispatchQueue

    // Semaphore needed to perform async operation (Loading) as sync
    private let semaphore = DispatchSemaphore(value: 1)

    init(queueLabelSuffix: String) {
        // This is needed to correctly create a different queues for different classes and instances of class
        QueuedExecutorIdentifier.identifier += 1
        syncQueue = DispatchQueue(label: "QueuedLoader:\(queueLabelSuffix)#\(QueuedExecutorIdentifier.identifier)")
    }
    
    /// Execute given operations in a serial queue
    /// - Parameters:
    ///   - executor: Closure which represents operation to be executed,
    ///               in the end of operation executor should call it's completion argument.
    ///   - completion: Closure which will be called after executor completion.
    func executeInQueue(executor: @escaping ExecutorClosure, completion: @escaping Completion) {
        syncQueue.async { [weak self] in
            // Executor operation can be asynchronous,
            // So to execute it logically-correct in serial queue
            // Using blocking mechanism
            // Tts already inside the syncQueue, so blocking works as expected
            self?.semaphore.wait()
            executor { [weak self] error in
                // Unlock due we finished operation in syncQueue
                self?.semaphore.signal()
                completion(error)
            }
        }
    }
}
