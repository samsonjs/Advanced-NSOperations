/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file defines the OperationObserver protocol.
*/

import Foundation

/**
    The protocol that types may implement if they wish to be notified of significant
    operation lifecycle events.
*/
protocol EarthquakeOperationObserver {
    
    /// Invoked immediately prior to the `EarthquakeOperation`'s `execute()` method.
    func operationDidStart(operation: EarthquakeOperation)
    
    /// Invoked when `EarthquakeOperation.produceOperation(_:)` is executed.
    func operation(operation: EarthquakeOperation, didProduceOperation newOperation: Operation)
    
    /**
        Invoked as an `EarthquakeOperation` finishes, along with any errors produced during
        execution (or readiness evaluation).
    */
    func operationDidFinish(operation: EarthquakeOperation, errors: [NSError])
    
}
