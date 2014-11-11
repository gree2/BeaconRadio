//
//  MeasurementModel.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 10/11/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation

class MeasurementModel {
    
    func weightParticle(particle: Particle, withMap map: Map) -> Double {
        var weight = 0.0
        
        if map.isCellFree(Position(x: particle.x, y: particle.y)) {
           weight = 1.0
        }
        
        return weight
    }
}