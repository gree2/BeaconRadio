//
//  BeaconModel.swift
//  IndoorLocalization
//
//  Created by Thomas Bopst on 07/10/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation
import CoreLocation


class BeaconRadar: NSObject, CLLocationManagerDelegate, IBeaconRadar {
    
    private let locationManager = CLLocationManager()
    
    private let uuid: NSUUID
    private let beaconRegion: CLBeaconRegion

    private var observers = NSMutableSet()

    private var rangedBeacons = Dictionary<String, Beacon>()
    private let dataLogger = DataLogger(attributeNames: ["uuid", "major", "minor", "accuracy", "rssi", "proximity"])
    private lazy var dateFormatter: NSDateFormatter = {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd_HH-mm"
        return dateFormatter
        }()
    
    
    required init(uuid: NSUUID) {
        
        self.uuid = uuid
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
            self.dataLogger.start()
        }
    }
    
    private func stopRanging() {
        self.locationManager.stopRangingBeaconsInRegion(self.beaconRegion)
        
        if let path = Util.pathToLogfileWithName("\(self.dateFormatter.stringFromDate(NSDate()))_Beacon.csv") {
            self.dataLogger.save(dataStoragePath: path, error: nil)
        }
        
        
    }
    
    func getBeacons() -> [Beacon] {
        return self.rangedBeacons.values.array
    }
    
    func getBeacon(beaconID: BeaconID) -> Beacon? {
        return self.rangedBeacons[beaconID.description()]
    }
    
    func getBeacon(beaconID: String) -> Beacon? {
        return self.rangedBeacons[beaconID]
    }
    
    
    // MARK: CLLocationManagerDelegate
    func locationManager(manager: CLLocationManager!, didRangeBeacons beacons: [AnyObject]!, inRegion region: CLBeaconRegion!) {
        
        self.rangedBeacons.removeAll(keepCapacity: false)
        
        var log = [[String:String]]()
        
        for beacon in beacons {
            if beacon is CLBeacon {
                let clB = beacon as CLBeacon
                
                let b = Beacon(
                    proximityUUID: clB.proximityUUID,
                    major: clB.major.integerValue,
                    minor: clB.minor.integerValue,
                    proximity: clB.proximity,
                    accuracy: clB.accuracy,
                    rssi: clB.rssi
                )
                
                self.rangedBeacons.updateValue(b, forKey: b.identifier)

                
                
                log.append(["uuid":b.proximityUUID.UUIDString, "major":"\(b.major)", "minor":"\(b.minor)", "accuracy":"\(b.accuracy)", "rssi":"\(b.rssi)", "proximity":"\(b.proximity.rawValue)"])
            }
        }
        
        self.dataLogger.log(log)
        
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
