//
//  Particle.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 31/10/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

struct Particle {
    let x: UInt // cm
    let y: UInt // cm
    let orientation: UInt // degree*10
    
    init(x: UInt, y: UInt, orientation: UInt) {
        
        self.x = x
        self.y = y
        
        if 0 < orientation  && orientation < 3600 {
            self.orientation = orientation
        } else {
            self.orientation = 0
        }
    }
}