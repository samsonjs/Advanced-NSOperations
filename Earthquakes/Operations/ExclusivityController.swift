/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
The file contains the code to automatically set up dependencies between mutually exclusive operations.
*/

import Foundation

/**
    `ExclusivityController` is a singleton to keep track of all the in-flight
    `EarthquakeOperation` instances that have declared themselves as requiring
    mutual exclusivity. We use a singleton because mutual exclusivity must be enforced
    across the entire app, regardless of the `EarthquakeOperationQueue` on which an
    `EarthquakeOperation` was executed.
*/
class ExclusivityController {
    static let sharedExclusivityController = ExclusivityController()
    
    private let serialQueue = DispatchQueue(label: "Operations.ExclusivityController")
    private var operations: [String: [EarthquakeOperation]] = [:]
    
    private init() {
        /*
            A private initializer effectively prevents any other part of the app
            from accidentally creating an instance.
        */
    }
    
    /// Registers an operation as being mutually exclusive
    func addOperation(operation: EarthquakeOperation, categories: [String]) {
        /*
            This needs to be a synchronous operation.
            If this were async, then we might not get around to adding dependencies
            until after the operation had already begun, which would be incorrect.
        */
        serialQueue.sync {
            for category in categories {
                self.noqueue_addOperation(operation: operation, category: category)
            }
        }
    }
    
    /// Unregisters an operation from being mutually exclusive.
    func removeOperation(operation: EarthquakeOperation, categories: [String]) {
        serialQueue.async {
            for category in categories {
                self.noqueue_removeOperation(operation: operation, category: category)
            }
        }
    }
    
    
    // MARK: Operation Management
    
    private func noqueue_addOperation(operation: EarthquakeOperation, category: String) {
        var operationsWithThisCategory = operations[category] ?? []
        
        if let last = operationsWithThisCategory.last {
            operation.addDependency(last)
        }
        
        operationsWithThisCategory.append(operation)

        operations[category] = operationsWithThisCategory
    }
    
    private func noqueue_removeOperation(operation: EarthquakeOperation, category: String) {
        let matchingOperations = operations[category]

        if var operationsWithThisCategory = matchingOperations,
           let index = operationsWithThisCategory.firstIndex(of: operation) {

            operationsWithThisCategory.remove(at: index)
            operations[category] = operationsWithThisCategory
        }
    }
    
}
