//
//  ParticleFilter.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 04/11/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation

class ParticleFilter: NSObject, Observable {
    
    let map: Map
    
    private let runFilterTimeInterval = 2.0
    private var runFilterTimer: NSTimer?
    private lazy var operationQueue: NSOperationQueue = {
        let queue = NSOperationQueue()
        queue.qualityOfService = .UserInitiated
        return queue
    }()
    
    private let particleSetSize = 10
    private var particleSet: [Particle] = [] {
        didSet {
            notifyObservers()
        }
    }
    
    private lazy var motionModel = MotionModel()
    private lazy var measurementModel = MeasurementModel()
    
    
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
        super.init()        
    }
    
    func startLocalization() {
        
        if self.particleSet.isEmpty {
            let operation = NSBlockOperation({
                let particles = self.generateParticleSet()
                
                // MainThread: set particles and notify Observers
                let updateOp = NSBlockOperation(block: {
                    self.particleSet = particles
                    self.startTimer()
                })
                NSOperationQueue.mainQueue().addOperation(updateOp)
            })
            
            self.operationQueue.addOperation(operation)
            
        } else {
            startTimer()
        }
        
        // start MotionTracking
        self.motionModel.startMotionTracking()
    }
    
    private func startTimer() {
        // setup NSTimer
        runFilterTimer = NSTimer(timeInterval: runFilterTimeInterval, target: self, selector: "filter", userInfo: nil, repeats: true)
        NSRunLoop.mainRunLoop().addTimer(runFilterTimer!, forMode: NSRunLoopCommonModes)
    }
    
    func stopLocalization() {
        runFilterTimer?.invalidate()
        runFilterTimer = nil
        
        self.motionModel.stopMotionTracking()
    }
    
    func filter() {
        
        let operation = NSBlockOperation(block: {
            println("Timer called")
            let particlesT0 = self.particles // copies particleset
            
            let motion = self.motionModel.motionDiffToLastMotion()
            println(motion.description())
            let particlesT1 = self.mcl(particlesT0, motion: motion)

            
            // MainThread: set particles and notify Observers
            let updateOp = NSBlockOperation(block: {
                self.particleSet = particlesT1 // -> notifyObservers
            })
            NSOperationQueue.mainQueue().addOperation(updateOp)
        })
        
        self.operationQueue.addOperation(operation)
    }
    
    // MARK: MCL algorithm
    private func mcl(particles_t0: [Particle], motion: MotionModel.MotionData) -> [Particle] {
        
        // integrate motion
        let particles_t1 = particles_t0.map({particle in Particle(x: particle.x + motion.x, y: particle.y + motion.y, orientation: motion.orientation)})
        
        // weight particles
        var weightedParticleSet: [(weight: Double,particle: Particle)] = []
        weightedParticleSet.reserveCapacity(particles_t1.count)
        
        for particle in particles_t1 {
            var weight: Double = self.measurementModel.weightParticle(particle, withMap: self.map)
            
            if weightedParticleSet.count > 1 {
                weight += weightedParticleSet.last!.0 // add weigt of predecessor
            }
            
            weightedParticleSet += [(weight: weight, particle: particle)]
        }
        
        
        // roulette
        var particles_t2: [Particle] = []
        particles_t2.reserveCapacity(weightedParticleSet.count)
        
        while particles_t2.count < self.particleSetSize {
            
            let random = Double(UInt(arc4random_uniform(UInt32(weightedParticleSet.last!.weight))))
            
            
            var index = 0
            
            for var i: Int = 0; i < weightedParticleSet.count; ++i {
                if weightedParticleSet[i].weight < random {
                    index = i
                } else {
                    break;
                }
            }
            particles_t2.append(weightedParticleSet[index].particle)
        }
        
        return particles_t2
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
        let theta = UInt(arc4random_uniform(360))
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