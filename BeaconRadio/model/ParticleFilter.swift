//
//  ParticleFilter.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 04/11/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation

class ParticleFilter: NSObject, Observable, Observer {
    
    let map: Map
    
    private let runFilterTimeInterval = 1.0
    private var runFilterTimer: NSTimer?
    private lazy var operationQueue: NSOperationQueue = {
        let queue = NSOperationQueue()
        queue.qualityOfService = .UserInitiated
        return queue
    }()
    
    private let particleSetSize = 200
    private var particleSet: [Particle] = [] {
        didSet {
            notifyObservers()
        }
    }
    
    private lazy var beaconRadar: IBeaconRadar = BeaconRadarFactory.beaconRadar
    
    private lazy var motionModel = MotionModel()
    private lazy var measurementModel = MeasurementModel()
    private var _isRunning = false
    var isRunning: Bool {
        get {
            return _isRunning
        }
    }
    
    
    var particles: [Particle] {
        get {
            return self.particleSet
        }
    }
    
    private var weightedParticleSetMean: (x: Double, y: Double) = (0.0, 0.0)
    
    var particleSetMean: (x: Double, y: Double) {
        get {
//            let x = self.particleSet.reduce(0.0, combine: {$0 + $1.x})/Double(self.particleSetSize)
//            let y = self.particleSet.reduce(0.0, combine: {$0 + $1.y})/Double(self.particleSetSize)
//            return (x: x, y: y)
            return self.weightedParticleSetMean
        }
    }
    
    
    var estimatedPath = [Pose]()
    
    var motionPath: [Pose] {
        return self.motionModel.estimatedPath
    }
    
    
    init(map: Map) {
        self.map = map
        super.init()
    }
    
    func startLocalization() {
        
        // start MotionTracking
        self.motionModel.startMotionTracking()
        self.measurementModel.startBeaconRanging()
        
        // register for beacon updates and wait until first beacons are received
        // particle generation around beacons
        self.beaconRadar.addObserver(self)
        
        self._isRunning = true
    }
    
    private func startTimer() {
        // setup NSTimer
        runFilterTimer = NSTimer(timeInterval: runFilterTimeInterval, target: self, selector: "filter", userInfo: nil, repeats: false)
        NSRunLoop.mainRunLoop().addTimer(runFilterTimer!, forMode: NSRunLoopCommonModes)
    }
    
    func stopLocalization() {
        
        self._isRunning = false
        
        runFilterTimer?.invalidate()
        runFilterTimer = nil
        
        self.motionModel.stopMotionTracking()
        self.measurementModel.stopBeaconRanging()
    }
    
    func filter() {
        
        self.operationQueue.addOperationWithBlock({
            
            let particlesT0 = self.particles // copies particleset
            let startTime = NSDate()
            
            let particlesT1 = self.mcl(particlesT0, map: self.map)

            let endTime = NSDate().timeIntervalSinceDate(startTime)
            println("ParticleFilter Duration: \(endTime)")
            
            // MainThread: set particles and notify Observers
            let updateOp = NSBlockOperation(block: {
                self.startTimer()
                self.particleSet = particlesT1 // -> notifyObservers
            })
            NSOperationQueue.mainQueue().addOperation(updateOp)
            
        })
    }
    
    // MARK: MCL algorithm
    
    private var w_slow = 0.0
    private var w_fast = 0.0
    private var mcl_callCount = 0
    
    private func mcl(particles_tMinus1: [Particle], map: Map) -> [Particle] {
        
        var w_avg: Double = 0.0
        
        // motions
        let motions = self.motionModel.latestMotions // get copy of motions
        self.motionModel.resetMotionStore() // delete motions
        
        if motions.isEmpty && ++mcl_callCount < 3 {
            return particles_tMinus1
        } else {
            mcl_callCount = 0
        }
        
        // Sample motion + weight particles
        var weightedParticleSet: [(weight: Double,particle: Particle)] = []
        weightedParticleSet.reserveCapacity(self.particleSetSize)
        
        // Distance measurements to Beacons
        let measurements = self.measurementModel.measurements
        self.measurementModel.resetMeasurementStore()
        
        for particle in particles_tMinus1 {
            
            let sampleParticle = MotionModel.sampleParticlePoseForPose(particle, withMotions: motions, andMap: map)
            
            var w: Double = MeasurementModel.weightParticle(sampleParticle, withDistanceMeasurements: measurements, andMap: self.map)
            if w > 0 {
                
                w_avg += (1.0 / Double(self.particleSetSize)) * w
                
                // commute weights
                if weightedParticleSet.count > 1 {
                    w += weightedParticleSet.last!.0 // add weigt of predecessor
                }
                weightedParticleSet += [(weight: w, particle: sampleParticle)]
            }
        }
        
        let alpha_slow = 0.4
        let alpha_fast = 0.5
        
        w_slow += alpha_slow * (w_avg - w_slow)
        w_fast += alpha_fast * (w_avg - w_fast)
        println("w_avg: \(w_avg), w_slow: \(w_slow), w_fast: \(w_fast), w_fast/w_slow: \(w_fast/w_slow)")
        
        var weightedParticleSetMean: (x: Double, y: Double) = (0.0, 0.0)
        var weightSum = 0.0
        
        // roulette
        var particles_t: [Particle] = []
        particles_t.reserveCapacity(weightedParticleSet.count)
        
        var logCount_addedRandomParticleCount = 0
        
//        if !weightedParticleSet.isEmpty {

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
//                    var index = 0
//                    
//                    for var i: Int = 0; i < weightedParticleSet.count; ++i {
//                        if weightedParticleSet[i].weight < random {
//                            index = i
//                        } else {
//                            break;
//                        }
//                    }
                    // binary search
                    var m: Int = 0;
                    var left: Int = 0;
                    var right: Int = weightedParticleSet.count-1;
                    while left <= right {
                        m = (left + right)/2
                        if random < weightedParticleSet[m].weight {
                            right = m - 1
                        } else if random > weightedParticleSet[m].weight {
                            left = m + 1
                        } else {
                            break
                        }
                    }
                    
                    // drawn particle
                    let particle = weightedParticleSet[m].particle
                    let weight = weightedParticleSet[m].weight
                    
                    // calc weighted particleSetMean
                    weightedParticleSetMean.x += particle.x * weight
                    weightedParticleSetMean.y += particle.y * weight
                    weightSum += weight
                    
                    // add particle to new set
                    particles_t.append(particle)
                }
            }
        
            self.weightedParticleSetMean = (x: weightedParticleSetMean.x/weightSum, y: weightedParticleSetMean.y/weightSum)
            self.estimatedPath.append(Pose(x: self.weightedParticleSetMean.x, y: self.weightedParticleSetMean.y, theta: 0.0))
            
            //println("\(logCount_addedRandomParticleCount) random particles added.")
            Logger.sharedInstance.log(message: "AddedRandomParticleCount: \(logCount_addedRandomParticleCount)")
        
            return particles_t
//        } else {
//            // can happen if all particles are out of bounds
//            return generateParticleSet()
//        }
    }
    
    // MARK: Particle generation
    
    private func generateParticlesAroundBeacons(beacons: [Beacon]) -> [Particle] {
        
        var particles = [Particle]()
        
        for b in beacons {
            if let landmark = self.map.landmarks[b.identifier] {
                let xMin = max(0.0, landmark.x - (b.accuracy * 0.5))
                let xMax = min(self.map.size.x, landmark.x + (b.accuracy * 0.5))
                
                let yMin = max(0.0, landmark.y - (b.accuracy * 0.5))
                let yMax = min(self.map.size.y, landmark.y + (b.accuracy * 0.5))
                
                let size:Int = Int(ceil(Double(self.particleSetSize) / Double(beacons.count)))
                
                particles += generateParticleSetWithSize(size, xMin: xMin, xMax: xMax, yMin: yMin, yMax: yMax)
            }
        }
        return particles
    }
    
    private func generateParticleSet() -> [Particle] {
        return generateParticleSetWithSize(self.particleSetSize, xMin: 0, xMax: self.map.size.x, yMin: 0, yMax: self.map.size.y)
    }
    
    private func generateParticleSetWithSize(size: Int, xMin: Double, xMax: Double, yMin: Double, yMax: Double) -> [Particle] {
        
        var particles: [Particle] = []
        
        if 0 <= xMin && xMin < xMax && 0 <= yMin && yMin < yMax {
            while particles.count < size {
                
                // add random particle
                particles.append(generateRandomParticle(xMin: xMin, xMax: xMax, yMin: yMin, yMax: yMax))
            }
        }
        
        return particles
    }
    
    // returns particle that fits to the map's free space
    private func generateRandomParticle() -> Particle {
        return generateRandomParticle(xMin: 0, xMax: self.map.size.x, yMin: 0, yMax: self.map.size.y)
    }
    
    private func generateRandomParticle(#xMin: Double, xMax: Double, yMin: Double, yMax: Double) -> Particle {
        
        var x = 0.0
        var y = 0.0
        
        do {
            
            x = Double(arc4random_uniform(UInt32( (xMax-xMin) * 100)))/100.0 + xMin
            y = Double(arc4random_uniform(UInt32( (yMax-yMin) * 100)))/100.0 + yMin
            
        } while !self.map.isCellFree(x: x, y: y) // check if paricle coordinates fit to map
        
        let theta = Angle.deg2Rad(Double(arc4random_uniform(36000))/100.0)
        
        return Particle(x: x, y: y, theta: theta)
    }
    
    // MARK: Observer protocol - BeaconRadio
    func update() {
        // get Beacons ordered by accuracy ascending
        
        let beacons = self.beaconRadar.getBeacons().sorted({$0.accuracy < $1.accuracy})
        
        let particles = generateParticlesAroundBeacons(beacons)
        
        if self.particleSet.isEmpty && !particles.isEmpty {
            self.beaconRadar.removeObserver(self)
            self.particleSet = particles
        } else {
            self.beaconRadar.removeObserver(self)
        }
        startTimer()
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