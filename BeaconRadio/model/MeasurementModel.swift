//
//  MeasurementModel.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 10/11/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation


class MeasurementModel: Observer {
    
    private var beaconsInRange: [String: Double] = [:]
    
    init() {
        BeaconRadar.sharedInstance.addObserver(self)
    }
    
    deinit {
        BeaconRadar.sharedInstance.removeObserver(self)
    }
    
    func weightParticle(particle: Particle, withMap map: Map) -> Double {
        var weight = 0.0
        
        if map.isCellFree(particle.x, y: particle.y) {
            weight = 1.0
            
            for bID in self.beaconsInRange.keys {
                
                if let lm = map.landmarks[bID] {
                    let diffX = lm.x - particle.x
                    let diffY = lm.y - particle.y
                    
                    let d = sqrt( (diffX * diffX) + (diffY * diffY) )
                    let sigma_d_2 = pow(0.3131 * d + 0.0051, 2)
                    
                    let w = NormalDistribution.pdf(self.beaconsInRange[bID]!, mu: d, sigma_2: sigma_d_2)
                    
                    
//                    let dError = d - self.beaconsInRange[bID]!
//                    let w = NormalDistribution.pdf(dError, mu: 0, sigma_2: sigma_d_2)
                    weight *= w
                    
//                    println("LM: \(bID) -> Distance: \(d), measuredDistance: \(self.beaconsInRange[bID]!), weight: \(w)")
                }
            }
        }
        
        self.beaconsInRange.removeAll(keepCapacity: true)
        
        return weight
    }
    
    func update() {
        var rangedBeacons: [String: Double] = [:]
        
        for beacon in BeaconRadar.sharedInstance.getBeacons() {
            if (beacon.accuracy >= 0) {
                
                let id = "\(beacon.proximityUUID.UUIDString):\(beacon.major):\(beacon.minor)"
                
                rangedBeacons.updateValue(beacon.accuracy, forKey: id)
            }
        }
        self.beaconsInRange = rangedBeacons
    }
}