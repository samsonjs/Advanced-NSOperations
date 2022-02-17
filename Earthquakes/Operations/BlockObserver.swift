/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file shows how to implement the OperationObserver protocol.
*/

import Foundation

/**
    The `BlockObserver` is a way to attach arbitrary blocks to significant events
    in an `Operation`'s lifecycle.
*/
struct BlockObserver: OperationObserver {
    // MARK: Properties
    
    private let startHandler: ((EarthquakeOperation) -> Void)?
    private let produceHandler: ((EarthquakeOperation, Operation) -> Void)?
    private let finishHandler: ((EarthquakeOperation, [NSError]) -> Void)?
    
    init(startHandler: ((EarthquakeOperation) -> Void)? = nil, produceHandler: ((EarthquakeOperation, Operation) -> Void)? = nil, finishHandler: ((EarthquakeOperation, [NSError]) -> Void)? = nil) {
        self.startHandler = startHandler
        self.produceHandler = produceHandler
        self.finishHandler = finishHandler
    }
    
    // MARK: OperationObserver
    
    func operationDidStart(operation: EarthquakeOperation) {
        startHandler?(operation)
    }
    
    func operation(operation: EarthquakeOperation, didProduceOperation newOperation: Operation) {
        produceHandler?(operation, newOperation)
    }
    
    func operationDidFinish(operation: EarthquakeOperation, errors: [NSError]) {
        finishHandler?(operation, errors)
    }
}
