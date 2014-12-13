//
//  MeasurementModel.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 10/11/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation


class MeasurementModel: Observer {
    
    typealias Measurement = (timestamp: NSDate, z: [String:Double])
    
    private var beaconsInRange: [Measurement] = []

    
    var measurements: [Measurement] {
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
    
    func resetMeasurementStore() {
        self.beaconsInRange.removeAll(keepCapacity: false)
    }
    
    func returnResidualMeasurements(z: [Measurement]) {
        self.beaconsInRange = (self.beaconsInRange + z).sorted({$0.timestamp.compare($1.timestamp) == NSComparisonResult.OrderedAscending})
    }
    
    // MARK: Observer protocol
    func update() {
//        var rangedBeacons = self.beaconsInRange // copies dict

        var z: Measurement = (timestamp: NSDate(), z: [String:Double]())
        
        for beacon in BeaconRadarFactory.beaconRadar.getBeacons() {
            if (beacon.accuracy >= 0) {
                
                let id = "\(beacon.proximityUUID.UUIDString):\(beacon.major):\(beacon.minor)"

                z.z[id] = beacon.accuracy
            }
        }
        self.beaconsInRange.append(z)
    }
    
    
    //MARK: Particle weighting
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
}