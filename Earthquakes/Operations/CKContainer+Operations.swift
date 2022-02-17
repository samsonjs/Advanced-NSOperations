/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
A convenient extension to CloudKit.CKContainer.
*/

import CloudKit

extension CKContainer {
    /**
        Verify that the current user has certain permissions for the `CKContainer`,
        and potentially requesting the permission if necessary.
        
        - parameter permission: The permissions to be verified on the container.

        - parameter shouldRequest: If this value is `true` and the user does not
            have the passed `permission`, then the user will be prompted for it.

        - parameter completion: A closure that will be executed after verification
            completes. The `NSError` passed in to the closure is the result of either
            retrieving the account status, or requesting permission, if either
            operation fails. If the verification was successful, this value will
        be `nil`.
    */
    func verifyPermission(permission: CKContainer.ApplicationPermissions, requestingIfNecessary shouldRequest: Bool = false, completion: @escaping (Error?) -> Void) {
        verifyAccountStatus(container: self, permission: permission, shouldRequest: shouldRequest, completion: completion)
    }
}

/**
    Make these helper functions instead of helper methods, so we don't pollute
    `CKContainer`.
*/
private func verifyAccountStatus(container: CKContainer, permission: CKContainer.ApplicationPermissions, shouldRequest: Bool, completion: @escaping (Error?) -> Void) {
    container.accountStatus { accountStatus, accountError in
        if accountStatus == .available {
            if permission != [] {
                verifyPermission(container: container, permission: permission, shouldRequest: shouldRequest, completion: completion)
            }
            else {
                completion(nil)
            }
        }
        else {
            let error = accountError ?? NSError(domain: CKErrorDomain, code: CKError.Code.notAuthenticated.rawValue, userInfo: nil)
            completion(error)
        }
    }
}

private func verifyPermission(container: CKContainer, permission: CKContainer.ApplicationPermissions, shouldRequest: Bool, completion: @escaping (Error?) -> Void) {
    container.status(forApplicationPermission: permission) { permissionStatus, permissionError in
        if permissionStatus == .granted {
            completion(nil)
        }
        else if permissionStatus == .initialState && shouldRequest {
            requestPermission(container: container, permission: permission, completion: completion)
        }
        else {
            let error = permissionError ?? NSError(domain: CKErrorDomain, code: CKError.Code.permissionFailure.rawValue, userInfo: nil)
            completion(error)
        }
    }
}

private func requestPermission(container: CKContainer, permission: CKContainer.ApplicationPermissions, completion: @escaping (Error?) -> Void) {
    DispatchQueue.main.async {
        container.requestApplicationPermission(permission) { requestStatus, requestError in
            if requestStatus == .granted {
                completion(nil)
            }
            else {
                let error = requestError ?? NSError(domain: CKErrorDomain, code: CKError.Code.permissionFailure.rawValue, userInfo: nil)
                completion(error)
            }
        }
    }
}
