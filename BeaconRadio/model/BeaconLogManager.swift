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
    let timestamp: NSDate
    let proximity: CLProximity
    let accuracy: Double?
    let rssi: Int?
    
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
    let logCapacity: Int?// per beacon
    
    init() {
        
    }
    
    init(capacity: Int) {
        self.logCapacity = capacity
    }
    
    func addLogEntry(beacon: CLBeacon) {
        
        let bID = BeaconID(proximityUUID: beacon.proximityUUID, major: beacon.major, minor: beacon.minor)
        let logEntry = LogEntry(timestamp: NSDate(), proximity: beacon.proximity, accuracy: beacon.accuracy, rssi: beacon.rssi)
        
        let bIDDescription = bID.description()
        
        if ((self.beacons[bIDDescription]) != nil) {
            // beacon does already exist in log --> add log entry
            
            if self.logCapacity != nil && self.beacons[bIDDescription]?.log.count >= self.logCapacity! {
                self.beacons[bIDDescription]?.log.removeAtIndex(0)
            }
            self.beacons[bIDDescription]?.log.append(logEntry)
            
        } else {
            // beacon does not exist in log --> add new beacon
            self.beacons[bIDDescription] = BeaconLog(id: bID, log: [logEntry])
            if self.logCapacity != nil {
                self.beacons[bIDDescription]?.log.reserveCapacity(self.logCapacity!)
            }
        }
    }
    
    func clearLog() {
        self.beacons.removeAll(keepCapacity: false)
    }
        
    func getBeacons() -> [BeaconID] {
        var result = [BeaconID]()
        
        for beacon in self.beacons {
            result.append(beacon.1.id)
        }
        return result
    }
    
    func getLatestLogEntryForBeacon(beacon: BeaconID) -> LogEntry? {
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
    
    func save2File(filename: String) {
        
        let dirs : [String]? = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true) as? [String]

        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        
        
        if let directories = dirs {
            let dir = directories[0]; //documents directory
            let path = dir.stringByAppendingPathComponent(filename);
            var content:String = ""
            
            for key in self.beacons.keys {
                
                let beaconLog = self.beacons[key]!
                
                content += "# \(beaconLog.id.description())\n"
                content += "timestamp | rssi (db) | accuracy (m) | proximity\n"
                
                for logEntry in beaconLog.log {
                    content += "\(dateFormatter.stringFromDate(logEntry.timestamp))|\(logEntry.rssi!)|\(logEntry.accuracy!)|\(logEntry.proximity.description())\n"
                }
            }
            
            
            //writing
            content.writeToFile(path, atomically: false, encoding: NSUTF8StringEncoding, error: nil);
        }
    }
    
    func countLogEntriesForBeacon(beacon: BeaconID) -> Int? {
        return self.beacons[beacon.description()]?.log.count
    }
}