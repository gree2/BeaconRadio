//
//  BeaconModel.swift
//  IndoorLocalization
//
//  Created by Thomas Bopst on 07/10/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation
import CoreLocation


class BeaconModel: NSObject, CLLocationManagerDelegate, Observable {
    
    // MARK: Singleton
    class var sharedInstance: BeaconModel {
    struct Static {
        static var instance: BeaconModel?
        static var token: dispatch_once_t = 0
        }
        dispatch_once(&Static.token) {
            Static.instance = BeaconModel()
        }
        return Static.instance!
    }
    
    let uuid = NSUUID(UUIDString: "F0018B9B-7509-4C31-A905-1A27D39C003C")
    let beaconRegion: CLBeaconRegion?
    let locationManager: CLLocationManager?
    
    let logManager = BeaconLogManager()
    
    
    override init() {
        super.init()
        
        self.locationManager = CLLocationManager()
        self.locationManager?.delegate = self
        self.beaconRegion = CLBeaconRegion(proximityUUID: uuid, identifier: "BeaconInside")
    }
    
    func startRanging() {
        
        if !isAuthorized() {
            askForAuthorization()
        } else if CLLocationManager.isRangingAvailable() {
            self.locationManager?.startRangingBeaconsInRegion(beaconRegion)
        }
    }
    
    func stopRanging() {
        if let bRegion = self.beaconRegion {
            self.locationManager?.stopRangingBeaconsInRegion(bRegion)
        }
    }
    
    private func isAuthorized()->Bool {
        return CLLocationManager.authorizationStatus() == CLAuthorizationStatus.Authorized
    }
    
    private func askForAuthorization() {
        if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.NotDetermined {
            self.locationManager?.requestAlwaysAuthorization()
        }
    }
    
    func getBeacons() -> [BeaconID] {
        return logManager.getBeacons()
    }
    
    func getActualLogEntryForBeacon(beacon: BeaconID) -> LogEntry? {
        return logManager.getActualLogEntryForBeacon(beacon)
    }
    
    
    // MARK: CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager!, didRangeBeacons beacons: [AnyObject]!, inRegion region: CLBeaconRegion!) {
        //println("# Beacons in region '\(region.identifier)'")
        
        for beacon in beacons {
            if beacon is CLBeacon {
                logManager.addLogEntry(beacon as CLBeacon)
                notifyObservers()
                
                //println("  - Major: \(beacon.major), Minor: \(beacon.minor), RSSI: \(beacon.rssi), Accuracy: \(beacon.accuracy), Proximity: \(beacon.proximity.toRaw())")
            }
        }
    }
    
    func locationManager(manager: CLLocationManager!, rangingBeaconsDidFailForRegion region: CLBeaconRegion!, withError error: NSError!) {
        println("  - ERROR: \(error.description)")
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        println("#Request Authorization state")
        startRanging()
    }
    
    // MARK: Observable
    private var observers = NSMutableSet()
    
    func addObserver(o: Observer) {
        observers.addObject(o)
    }
    
    func removeObserver(o: Observer) {
        observers.removeObject(o)
    }
    
    func notifyObservers() {
        for observer in observers {
            observer.update()
        }
    }

}
