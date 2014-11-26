//
//  Landmark.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 14/11/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation
import CoreLocation


// typealias Beacon = Landmark

struct Landmark {
    // identifier
    let uuid: NSUUID
    let major: UInt
    let minor: UInt
    
    // position
    let x: Double // Unit: m
    let y: Double // Unit: m
    
    var idString:String {
        get {
           return "\(uuid.UUIDString):\(major):\(minor)"
        }
    }
}