//
//  ParticleFilter.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 04/11/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation

class ParticleFilter: Observable {
    
    let map: Map
    
    private let particleSetSize = 100
    private var particleSet: [Particle] = []
    
    var particles: [Particle] {
        get {
            var result: [Particle] = []
            result.reserveCapacity(self.particleSet.count)
            for p in self.particleSet {
                result.append(p)
            }
            return result
        }
    }
    
    init(map: Map) {
        self.map = map
        self.particleSet = generateParticleSet()
    }
    
    // MARK: Particle generation
    private func generateParticleSet() -> [Particle] {
        
        var particles: [Particle] = []
        
        while particles.count < self.particleSetSize {
            
            // generate random x, y , theta values
            let particle = generateRandomParticle()
            
            // check if paricle coordinates fit to map
            if isParticleValid(particle) {
                particles.append(particle)
            }
            
        }
        
        return particles
    }
    
    private func generateRandomParticle() -> Particle {
        let x = UInt(arc4random_uniform(UInt32(self.map.sizeInCm.x)))
        let y = UInt(arc4random_uniform(UInt32(self.map.sizeInCm.y)))
        let theta = UInt(arc4random_uniform(3600))
        return Particle(x: x, y: y, orientation: theta)
    }
    
    private func isParticleValid(particle: Particle) -> Bool {
        return map.isCellFree(Position(x: particle.x, y: particle.y))
    }
    
    // MARK: Observable protocol
    
    private var observers = NSMutableSet()
    
    func addObserver(o: Observer) {
        observers.addObject(o)
    }
    
    func removeObserver(o: Observer) {
        observers.removeObject(o)
    }
    
    func notifyObservers() {
        for observer in observers {
            observer.update()
        }
    }
}