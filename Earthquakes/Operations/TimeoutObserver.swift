/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file shows how to implement the OperationObserver protocol.
*/

import Foundation

/**
    `TimeoutObserver` is a way to make an `EarthquakeOperation` automatically time out and
    cancel after a specified time interval.
*/
struct TimeoutObserver {
    // MARK: Properties

    static let timeoutKey = "Timeout"
    
    private let timeout: Int
    
    // MARK: Initialization
    
    init(timeout: Int) {
        self.timeout = timeout
    }
}

// MARK: EarthquakeOperationObserver

extension TimeoutObserver: EarthquakeOperationObserver {    
    func operationDidStart(operation: EarthquakeOperation) {
        // When the operation starts, queue up a block to cause it to time out.
        DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + .seconds(timeout)) {
            /*
                Cancel the operation if it hasn't finished and hasn't already
                been cancelled.
            */
            if !operation.isFinished && !operation.isCancelled {
                let error = NSError(code: .ExecutionFailed, userInfo: [
                    type(of: self).timeoutKey: self.timeout
                ])

                operation.cancelWithError(error: error)
            }
        }
    }

    func operation(operation: EarthquakeOperation, didProduceOperation newOperation: Operation) {
        // No op.
    }

    func operationDidFinish(operation: EarthquakeOperation, errors: [NSError]) {
        // No op.
    }
}
