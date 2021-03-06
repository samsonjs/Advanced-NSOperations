/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Shows how to retrieve the user's location with an operation.
*/

import Foundation
import CoreLocation

/**
    `LocationOperation` is an `EarthquakeOperation` subclass to do
    a "one-shot" request to get the user's current location, with a desired accuracy.
    This operation will prompt for `WhenInUse` location authorization, if the app
    does not already have it.
*/
class LocationOperation: EarthquakeOperation, CLLocationManagerDelegate {
    // MARK: Properties
    
    private let accuracy: CLLocationAccuracy
    private var manager: CLLocationManager?
    private let handler: (CLLocation) -> Void
    
    // MARK: Initialization
 
    init(accuracy: CLLocationAccuracy, locationHandler: @escaping (CLLocation) -> Void) {
        self.accuracy = accuracy
        self.handler = locationHandler
        super.init()
        addCondition(condition: LocationCondition(usage: .WhenInUse))
        addCondition(condition: MutuallyExclusive<CLLocationManager>())
    }
    
    override func execute() {
        DispatchQueue.main.async {
            /*
                `CLLocationManager` needs to be created on a thread with an active
                run loop, so for simplicity we do this on the main queue.
            */
            let manager = CLLocationManager()
            manager.desiredAccuracy = self.accuracy
            manager.delegate = self
            manager.startUpdatingLocation()
            
            self.manager = manager
        }
    }
    
    override func cancel() {
        DispatchQueue.main.async {
            self.stopLocationUpdates()
            super.cancel()
        }
    }
    
    private func stopLocationUpdates() {
        manager?.stopUpdatingLocation()
        manager = nil
    }
    
    // MARK: CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, location.horizontalAccuracy <= accuracy else {
            return
        }
        
        stopLocationUpdates()
        handler(location)
        finish()
    }
    
    private func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        stopLocationUpdates()
        finishWithError(error: error)
    }
}
