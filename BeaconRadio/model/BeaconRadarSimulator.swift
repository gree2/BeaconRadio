//
//  BeaconRadarSimulator.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 24/11/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation
import CoreLocation

class BeaconRadarSimulator: IBeaconRadar, DataPlayerDelegate {
    
    private var observers = NSMutableSet()
    let dataPlayer = DataPlayer()
    private var isRanging = false
    private var rangedBeacons = Dictionary<String, Beacon>()
    
    required init(uuid: NSUUID) {

    }
    
    func isAuthorized()->Bool {
        return true
    }
    
    func isRangingAvailable() -> Bool {
        return true
    }
    
    func getBeacons() -> [Beacon] {
        return self.rangedBeacons.values.array
    }
    
    func getBeacon(beaconID: BeaconID) -> Beacon? { // Deprecated
        return rangedBeacons[beaconID.description()]
    }
    
    func getBeacon(beaconID: String) -> Beacon? {
        return rangedBeacons[beaconID]
    }
    
    
    private func start() {
        isRanging = true
        
        self.dataPlayer.load(dataStoragePath: Util.pathToLogfileWithName("2014-11-25_15-34-12_Beacon.csv")! , error: nil)
        self.dataPlayer.playback(self)
    }
    
    private func stop() {
        isRanging = false
    }
    
    // MARK: DataPlayerDelegate
    func dataPlayer(player: DataPlayer, handleData data: [[String:String]]) {
        
        var beacons = [String:Beacon]()
        
        for d in data {
            let uuid = NSUUID(UUIDString: d["uuid"]!)
            let major: Int = d["major"]!.toInt()!
            let minor: Int = d["minor"]!.toInt()!
            let proximity: CLProximity = CLProximity(rawValue: d["proximity"]!.toInt()!)!
            let accuracy: Double = NSString(string: d["accuracy"]!).doubleValue
            let rssi: Int = d["rssi"]!.toInt()!
            
            let b = Beacon(
                proximityUUID: uuid!,
                major: major,
                minor: minor,
                proximity: proximity,
                accuracy: accuracy,
                rssi: rssi)
            
            beacons[b.identifier] = b
        }
        
        self.rangedBeacons = beacons
        notifyObservers()
    }
    
    // MARK: Observable
    
    func addObserver(o: Observer) {
        observers.addObject(o)
        
        if !isRanging {
            start()
        }
    }
    
    func removeObserver(o: Observer) {
        observers.removeObject(o)
        
        if observers.count == 0  && isRanging  {
            stop()
        }
    }
    
    func notifyObservers() {
        for observer in observers {
            observer.update()
        }
    }
}