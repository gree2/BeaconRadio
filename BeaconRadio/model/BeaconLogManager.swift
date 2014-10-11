//
//  File.swift
//  IndoorLocalization
//
//  Created by Thomas Bopst on 08/10/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation
import CoreLocation

extension CLProximity {
    func description() -> String {
        switch self {
        case .Immediate:
            return "Immediate"
        case .Near:
            return "Near"
        case .Far:
            return "Far"
        case .Unknown:
            return "Unknown"
        }
    }
}


struct BeaconID {
    let proximityUUID: NSUUID
    let major: Int
    let minor: Int
    
    func description() -> String {
        return "\(proximityUUID.UUIDString):\(major):\(minor)"
    }

}

struct LogEntry {
    let proximity: CLProximity
    let accuracy: Double
    let rssi: Int
    
    func description() -> String {
        return "RSSI: \(rssi), Accuracy: \(accuracy), proximity: \(proximity.description())"
    }
}

class BeaconLogManager {

    struct BeaconLog {
        let id: BeaconID
        var log = [LogEntry]()
    }

    
    private var beacons = Dictionary<String, BeaconLog>()
    let logCapacity = 60 // per beacon
    
    init() {
        
    }
    
    func addLogEntry(beacon: CLBeacon) {
        let bID = BeaconID(proximityUUID: beacon.proximityUUID, major: beacon.major, minor: beacon.minor)
        let logEntry = LogEntry(proximity: beacon.proximity, accuracy: beacon.accuracy, rssi: beacon.rssi)
        
        let bIDDescription = bID.description()
        
        if ((self.beacons[bIDDescription]) != nil) {
            // beacon does already exist in log --> add log entry
            
            if self.beacons[bIDDescription]?.log.count >= logCapacity {
                self.beacons[bIDDescription]?.log.removeAtIndex(0)
            }
            self.beacons[bIDDescription]?.log.append(logEntry)
            
        } else {
            // beacon does not exist in log --> add new beacon
            self.beacons[bIDDescription] = BeaconLog(id: bID, log: [logEntry])
            self.beacons[bIDDescription]?.log.reserveCapacity(logCapacity)
        }
    }
    
    func getBeacons() -> [BeaconID] {
        var result = [BeaconID]()
        
        for beacon in self.beacons {
            result.append(beacon.1.id)
        }
        return result
    }
    
    func getActualLogEntryForBeacon(beacon: BeaconID) -> LogEntry? {
        let id = beacon.description()
        
        if let bLog = self.beacons[id] {
            return bLog.log.last
        }
        return nil
    }
    
    func getLogEntriesForBeacon(beacon: BeaconID) -> [LogEntry] {
        let id = beacon.description()
        
        if let bLog = self.beacons[id] {
            return bLog.log
        }
        return []
    }
}