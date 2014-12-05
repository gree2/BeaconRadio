//
//  BeaconRadarFactory.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 23/11/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation
import CoreLocation

class BeaconRadarFactory {
    
    private class var _beaconRadar: IBeaconRadar? {
        struct Static {
            static var instance: IBeaconRadar?
            static var token: dispatch_once_t = 0
            static let simulation = true
        }
        dispatch_once(&Static.token) {
            
            let uuid = NSUUID(UUIDString: "F0018B9B-7509-4C31-A905-1A27D39C003C")
            
            if Static.simulation {
                Static.instance = BeaconRadarSimulator(uuid: uuid!)
            } else {
                Static.instance = BeaconRadar(uuid: uuid!)
            }
            
        }
        return Static.instance!
    }
    
    class var beaconRadar: IBeaconRadar {
        get {
            return _beaconRadar!
        }
    }
}


protocol IBeaconRadar: Observable {
    init(uuid: NSUUID)
    func isAuthorized()->Bool
    func isRangingAvailable() -> Bool
    func getBeacons() -> [Beacon]
    func getBeacon(beaconID: BeaconID) -> Beacon? // Deprecated
    func getBeacon(beaconID: String) -> Beacon?
}