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

    
    var measurements: [String: Double] {
        get {
            return self.beaconsInRange
        }
    }
    
    init() {
        
    }

    func startBeaconRanging() {
        BeaconRadarFactory.beaconRadar.addObserver(self)
    }
    
    func stopBeaconRanging() {
        BeaconRadarFactory.beaconRadar.removeObserver(self)
    }
    
    class func weightParticle(particle: Particle, withDistanceMeasurements beaconsInRange: [String: Double],  andMap map: Map) -> Double {
        var weight = 0.0
        
        if map.isCellFree(x: particle.x, y: particle.y) {
            weight = 1.0
            
            for bID in beaconsInRange.keys {
                
                if let lm = map.landmarks[bID] {
                    let diffX = lm.x - particle.x
                    let diffY = lm.y - particle.y
                    
                    let d = sqrt( (diffX * diffX) + (diffY * diffY) )
//                    let sigma_d = max(0.3131 * d + 0.0051, 0.5) // standard deviation
                    let sigma_d = 0.1 * d // standard deviation
//                    let sigma_d_2 = pow(sigma_d, 2) // variance
                    
                    let d_measurment = beaconsInRange[bID]!
                    
                    let w = NormalDistribution.pdf(d_measurment, mu: d, sigma: sigma_d)
                    
                    weight *= w
                    
//                    println("LM: \(bID) -> Distance: \(d), measuredDistance: \(self.beaconsInRange[bID]!), weight: \(w)")
                }
            }
        }
        
        
        
        return weight
    }
    
    func resetMeasurementStore() {
        self.beaconsInRange.removeAll(keepCapacity: false)
    }
    
    // MARK: Observer protocol
    func update() {
        var rangedBeacons: [String: Double] = [:]
        
        for beacon in BeaconRadarFactory.beaconRadar.getBeacons() {
            if (beacon.accuracy >= 0) {
                
                let id = "\(beacon.proximityUUID.UUIDString):\(beacon.major):\(beacon.minor)"
                
                rangedBeacons.updateValue(beacon.accuracy, forKey: id)
            }
        }
        self.beaconsInRange = rangedBeacons
    }
}