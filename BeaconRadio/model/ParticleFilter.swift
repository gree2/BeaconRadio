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
    
    private let runFilterTimeInterval = 5.0
    private var runFilterTimer: NSTimer?
    private lazy var operationQueue: NSOperationQueue = {
        let queue = NSOperationQueue()
        queue.qualityOfService = .Background //.UserInitiated
        return queue
    }()
    
    private let particleSetSize = 50
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
            operation.qualityOfService = .UserInitiated
            self.operationQueue.addOperation(operation)
            
        } else {
            startTimer()
        }
        
        // start MotionTracking
        self.motionModel.startMotionTracking(self.operationQueue)
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
            
            let particlesT1 = self.mcl(particlesT0, map: self.map)
            
//            for p in particlesT1 {
//                println("\(p.description())")
//            }

            // MainThread: set particles and notify Observers
            let updateOp = NSBlockOperation(block: {
                self.particleSet = particlesT1 // -> notifyObservers
            })
            NSOperationQueue.mainQueue().addOperation(updateOp)
        })
        operation.qualityOfService = .UserInitiated
        self.operationQueue.addOperation(operation)
    }
    
    // MARK: MCL algorithm
    
    private var w_slow = 0.0
    private var w_fast = 0.0
    
    private func mcl(particles_tMinus1: [Particle], map: Map) -> [Particle] {
        
        var w_avg: Double = 0.0
        
        // integrate sample motion
        // estimated Pose based on MotionModel
        let mMPoseEstimation_tMinus1 = self.motionModel.lastPoseEstimation()
        let mMPoseEstimation_t = self.motionModel.computeNewPoseEstimation()
                
        let samplePoseParticles = particles_tMinus1.map({p in MotionModel.sampleParticlePoseForPose(p, withMotionFrom: mMPoseEstimation_tMinus1, to: mMPoseEstimation_t, and: map)})
        
        // weight particles
        var weightedParticleSet: [(weight: Double,particle: Particle)] = []
        weightedParticleSet.reserveCapacity(samplePoseParticles.count)
        
        for particle in samplePoseParticles {
            var w: Double = self.measurementModel.weightParticle(particle, withMap: self.map)
            if w > 0 {
                
                w_avg += (1.0 / Double(self.particleSetSize)) * w
                
                // commute weights
                if weightedParticleSet.count > 1 {
                    w += weightedParticleSet.last!.0 // add weigt of predecessor
                }
                weightedParticleSet += [(weight: w, particle: particle)]
            }
        }
        
        let alpha_slow = 0.1
        let alpha_fast = 0.3
        
        w_slow += alpha_slow * (w_avg - w_slow)
        w_fast += alpha_fast * (w_avg - w_fast)
        println("w_avg: \(w_avg), w_slow: \(w_slow), w_fast: \(w_fast), w_fast/w_slow: \(w_fast/w_slow)")
        
        // roulette
        var particles_t: [Particle] = []
        particles_t.reserveCapacity(weightedParticleSet.count)
        
        var logCount_addedRandomParticleCount = 0
        
        if !weightedParticleSet.isEmpty {

            while particles_t.count < self.particleSetSize {
                
                let p = Random.rand_uniform()
                let x = max( 0.0, 1.0 - (w_fast/w_slow))
                
                if p < x {
                    // add random particle
                    particles_t.append(generateRandomParticle())
                    ++logCount_addedRandomParticleCount
                } else {
                    // draw particle with probability
                    let random = Double(UInt(arc4random_uniform(UInt32(weightedParticleSet.last!.weight))))
                    var index = 0
                    
                    for var i: Int = 0; i < weightedParticleSet.count; ++i {
                        if weightedParticleSet[i].weight < random {
                            index = i
                        } else {
                            break;
                        }
                    }
                    
                    particles_t.append(weightedParticleSet[index].particle)
                }
                
            }
            
            // println("\(logCount_addedRandomParticleCount) random particles added.")
            Logger.sharedInstance.log(message: "AddedRandomParticleCount: \(logCount_addedRandomParticleCount)")
            
            return particles_t
        } else {
            // can happen if all particles are out of bounds
            return generateParticleSet()
        }
    }
    
    // MARK: Particle generation
    private func generateParticleSet() -> [Particle] {
        
        var particles: [Particle] = []
        
        while particles.count < self.particleSetSize {
            
            // add random particle
            particles.append(generateRandomParticle())
        }
        
        return particles
    }
    
    // returns particle that fits to the map's free space
    private func generateRandomParticle() -> Particle {
        
        var x = 0.0
        var y = 0.0
        
        do {
            
            x = Double(arc4random_uniform(UInt32(self.map.size.x * 100)))/100.0
            y = Double(arc4random_uniform(UInt32(self.map.size.y * 100)))/100.0
            
        } while !self.map.isCellFree(x, y: y) // check if paricle coordinates fit to map
        
        let theta = Angle.deg2Rad(Double(arc4random_uniform(36000))/100.0)
        
        return Particle(x: x, y: y, theta: theta)
    }
    
    func estimatedPath() -> [Pose] {
        return self.motionModel.estimatedPath
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