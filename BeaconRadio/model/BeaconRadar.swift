//
//  BeaconModel.swift
//  IndoorLocalization
//
//  Created by Thomas Bopst on 07/10/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation
import CoreLocation


class BeaconRadar: NSObject, CLLocationManagerDelegate, Observable {
    
    // MARK: Singleton
    class var sharedInstance: BeaconRadar {
    struct Static {
        static var instance: BeaconRadar?
        static var token: dispatch_once_t = 0
        }
        dispatch_once(&Static.token) {
            Static.instance = BeaconRadar()
        }
        return Static.instance!
    }

    private let locationManager = CLLocationManager()
    
    private let uuid = NSUUID(UUIDString: "F0018B9B-7509-4C31-A905-1A27D39C003C")
    private let beaconRegion: CLBeaconRegion

    private var observers = NSMutableSet()

    private var rangedBeacons = Dictionary<String, CLBeacon>()
    
    
    override init() {
        
        self.beaconRegion = CLBeaconRegion(proximityUUID: self.uuid, identifier: "BeaconInside")

        super.init()
        self.locationManager.delegate = self
        
        if !isAuthorized() {
            askForAuthorization()
        }
    }
    
    func isAuthorized()->Bool {
        return CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedWhenInUse
    }
    
    func isRangingAvailable() -> Bool {
        return CLLocationManager.isRangingAvailable()
    }
    
    private func askForAuthorization() {
        if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.NotDetermined {
            self.locationManager.requestWhenInUseAuthorization()
        }
    }
    
    private func isRanging() -> Bool {
        return self.locationManager.rangedRegions.count > 0
    }
    
    private func startRanging() {
        if isRangingAvailable() {
            self.locationManager.startRangingBeaconsInRegion(self.beaconRegion)
        }
    }
    
    private func stopRanging() {
        self.locationManager.stopRangingBeaconsInRegion(self.beaconRegion)
    }
    
    func getBeacons() -> [CLBeacon] {
        var beacons = [CLBeacon]()
        beacons.reserveCapacity(self.rangedBeacons.count)
        
        for beacon in self.rangedBeacons.values {
            beacons.append(beacon.copy() as CLBeacon)
        }
        return beacons
    }
    
    func getBeacon(beaconID: BeaconID) -> CLBeacon? {
        return self.rangedBeacons[beaconID.description()]
    }
    
    
    // MARK: CLLocationManagerDelegate
    func locationManager(manager: CLLocationManager!, didRangeBeacons beacons: [AnyObject]!, inRegion region: CLBeaconRegion!) {
        
        
        self.rangedBeacons.removeAll(keepCapacity: false)
        
        for beacon in beacons {
            if beacon is CLBeacon {
                let b = beacon as CLBeacon
                self.rangedBeacons.updateValue(b, forKey: BeaconID(proximityUUID: b.proximityUUID, major: b.major.integerValue, minor: b.minor.integerValue).description() )
            }
        }
        
        if self.rangedBeacons.count > 0 {
            notifyObservers()
        }
        
    }
    
    func locationManager(manager: CLLocationManager!, rangingBeaconsDidFailForRegion region: CLBeaconRegion!, withError error: NSError!) {
        println("  - ERROR: \(error.description)")
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        println("#Request Authorization state")
        
        if isAuthorized() && self.observers.count > 0  && !isRanging() {
            startRanging()
        } else if !isAuthorized() && isRanging() {
            stopRanging()
        }
    }
    
    // MARK: Observable

    func addObserver(o: Observer) {
        observers.addObject(o)
        
        if isAuthorized() && !isRanging() {
            startRanging()
        }
    }
    
    func removeObserver(o: Observer) {
        observers.removeObject(o)
        
        if observers.count == 0  && isRanging()  {
            stopRanging()
        }
    }
    
    func notifyObservers() {
        for observer in observers {
            observer.update()
        }
    }

}
