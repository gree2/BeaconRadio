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
    let orientation: UInt // degree
    
    init(x: UInt, y: UInt, orientation: UInt) {
        
        self.x = x
        self.y = y
        
        if 0 < orientation  && orientation < 360 {
            self.orientation = orientation
        } else {
            self.orientation = 0
        }
    }
    
    func description() -> String {
        return "Particle with x: \(self.x), y: \(self.y), orientation: \(self.orientation)"
    }
}