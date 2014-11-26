//
//  Beacon.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 24/11/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation
import CoreLocation


class Beacon {
    let proximityUUID: NSUUID
    let major: Int
    let minor: Int
    let proximity: CLProximity
    let accuracy: Double
    let rssi: Int
    
    init (proximityUUID: NSUUID, major: Int, minor: Int, proximity: CLProximity, accuracy: Double, rssi: Int) {
        self.proximityUUID = proximityUUID
        self.major = major
        self.minor = minor
        self.proximity = proximity
        self.accuracy = accuracy
        self.rssi = rssi
    }
    
    var identifier:String {
        get {
            return "\(self.proximityUUID.UUIDString):\(self.major):\(self.minor)"
        }
    }
    
    func description() -> String {
        return "ID: \(identifier), accuracy: \(accuracy), rssi: \(rssi), proximity: \(proximity.rawValue)"
    }
}
