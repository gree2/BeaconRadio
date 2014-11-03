//
//  Particle.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 31/10/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

struct Particle {
    let x: Double
    let y: Double
    let orientation: Double
    
    init(x: Double, y: Double, orientation: Double) {
        
        if x > 0 {
            self.x = x
        } else {
            self.x = 0
        }
        
        if y > 0 {
            self.y = y
        } else {
            self.y = 0
        }
        
        if 0 < orientation  && orientation < 360 {
            self.orientation = orientation
        } else {
            self.orientation = 0
        }
    }
}