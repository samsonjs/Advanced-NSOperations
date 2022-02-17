/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file shows an example of implementing the OperationCondition protocol.
*/

import CloudKit

/// A condition describing that the operation requires access to a specific CloudKit container.
struct CloudContainerCondition: OperationCondition {
    
    static let name = "CloudContainer"
    static let containerKey = "CKContainer"
    
    /*
        CloudKit has no problem handling multiple operations at the same time
        so we will allow operations that use CloudKit to be concurrent with each
        other.
    */
    static let isMutuallyExclusive = false
    
    let container: CKContainer // this is the container to which you need access.

    let permission: CKContainer.ApplicationPermissions
    
    /**
        - parameter container: the `CKContainer` to which you need access.
        - parameter permission: the `CKApplicationPermissions` you need for the
            container. This parameter has a default value of `[]`, which would get
            you anonymized read/write access.
    */
    init(container: CKContainer, permission: CKContainer.ApplicationPermissions = []) {
        self.container = container
        self.permission = permission
    }
    
    func dependencyForOperation(operation: EarthquakeOperation) -> Operation? {
        return CloudKitPermissionOperation(container: container, permission: permission)
    }
    
    func evaluateForOperation(operation: EarthquakeOperation, completion: @escaping (OperationConditionResult) -> Void) {
        container.verifyPermission(permission: permission, requestingIfNecessary: false) { error in
            if let error = error {
                let conditionError = NSError(code: .ConditionFailed, userInfo: [
                    OperationConditionKey: type(of: self).name,
                    type(of: self).containerKey: self.container,
                    NSUnderlyingErrorKey: error
                ])

                completion(.Failed(conditionError))
            }
            else {
                completion(.Satisfied)
            }
        }
    }
}

/**
    This operation asks the user for permission to use CloudKit, if necessary.
    If permission has already been granted, this operation will quickly finish.
*/
private class CloudKitPermissionOperation: EarthquakeOperation {
    let container: CKContainer
    let permission: CKContainer.ApplicationPermissions
    
    init(container: CKContainer, permission: CKContainer.ApplicationPermissions) {
        self.container = container
        self.permission = permission
        super.init()
        
        if permission != [] {
            /*
                Requesting non-zero permissions means that this potentially presents
                an alert, so it should not run at the same time as anything else
                that presents an alert.
            */
            addCondition(condition: AlertPresentation())
        }
    }
    
    override func execute() {
        container.verifyPermission(permission: permission, requestingIfNecessary: true) { error in
            self.finishWithError(error: error as NSError?)
        }
    }
    
}
