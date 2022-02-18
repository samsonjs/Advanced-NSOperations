/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file shows an example of implementing the OperationCondition protocol.
*/

import CoreLocation

/// A condition for verifying access to the user's location.
struct LocationCondition: OperationCondition {
    /**
        Declare a new enum instead of using `CLAuthorizationStatus`, because that
        enum has more case values than are necessary for our purposes.
    */
    enum Usage {
        case WhenInUse
        case Always
    }
    
    static let name = "Location"
    static let locationServicesEnabledKey = "CLLocationServicesEnabled"
    static let authorizationStatusKey = "CLAuthorizationStatus"
    static let isMutuallyExclusive = false
    
    let usage: Usage
    
    init(usage: Usage) {
        self.usage = usage
    }
    
    func dependencyForOperation(operation: EarthquakeOperation) -> Operation? {
        return LocationPermissionOperation(usage: usage)
    }
    
    func evaluateForOperation(operation: EarthquakeOperation, completion: (OperationConditionResult) -> Void) {
        let enabled = CLLocationManager.locationServicesEnabled()
        let actual = CLLocationManager().authorizationStatus
        
        var error: NSError?

        // There are several factors to consider when evaluating this condition
        switch (enabled, usage, actual) {
        case (true, _, .authorizedAlways):
                // The service is enabled, and we have "Always" permission -> condition satisfied.
                break

        case (true, .WhenInUse, .authorizedWhenInUse):
                /*
                    The service is enabled, and we have and need "WhenInUse"
                    permission -> condition satisfied.
                */
                break

            default:
                /*
                    Anything else is an error. Maybe location services are disabled,
                    or maybe we need "Always" permission but only have "WhenInUse",
                    or maybe access has been restricted or denied,
                    or maybe access hasn't been request yet.
                    
                    The last case would happen if this condition were wrapped in a `SilentCondition`.
                */
                error = NSError(code: .ConditionFailed, userInfo: [
                    OperationConditionKey: type(of: self).name,
                    type(of: self).locationServicesEnabledKey: enabled,
                    type(of: self).authorizationStatusKey: Int(actual.rawValue)
                ])
        }
        
        if let error = error {
            completion(.Failed(error))
        }
        else {
            completion(.Satisfied)
        }
    }
}

/**
    A private `EarthquakeOperation` that will request permission to access the user's location,
    if permission has not already been granted.
*/
private class LocationPermissionOperation: EarthquakeOperation {
    let usage: LocationCondition.Usage
    var manager: CLLocationManager?
    
    init(usage: LocationCondition.Usage) {
        self.usage = usage
        super.init()
        /*
            This is an operation that potentially presents an alert so it should
            be mutually exclusive with anything else that presents an alert.
        */
        addCondition(condition: AlertPresentation())
    }
    
    override func execute() {
        /*
            Not only do we need to handle the "Not Determined" case, but we also
            need to handle the "upgrade" (.WhenInUse -> .Always) case.
        */
        switch (CLLocationManager().authorizationStatus, usage) {
        case (.notDetermined, _), (.authorizedWhenInUse, .Always):
                DispatchQueue.main.async {
                    self.requestPermission()
                }

            default:
                finish()
        }
    }
    
    private func requestPermission() {
        manager = CLLocationManager()
        manager?.delegate = self

        let key: String
        
        switch usage {
            case .WhenInUse:
                key = "NSLocationWhenInUseUsageDescription"
                manager?.requestWhenInUseAuthorization()
        
            case .Always:
                key = "NSLocationAlwaysUsageDescription"
                manager?.requestAlwaysAuthorization()
        }
        
        // This is helpful when developing the app.
        assert(Bundle.main.object(forInfoDictionaryKey: key) != nil, "Requesting location permission requires the \(key) key in your Info.plist")
    }
    
}

extension LocationPermissionOperation: CLLocationManagerDelegate {
    @available(iOS 14.0, *)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager == self.manager && isExecuting && manager.authorizationStatus != .notDetermined {
            finish()
        }
    }
}
