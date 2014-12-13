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
    private let desiredParticleDiversity = 0.20 // in %
    
    private lazy var beaconRadar: IBeaconRadar = BeaconRadarFactory.beaconRadar
    
    private var motionModel: MotionModel
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
        self.motionModel = MotionModel(map: map)
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
        runFilterTimer = NSTimer(timeInterval: runFilterTimeInterval, target: self, selector: "mcl", userInfo: nil, repeats: false)
        NSRunLoop.mainRunLoop().addTimer(runFilterTimer!, forMode: NSRunLoopCommonModes)
    }
    
    func stopLocalization() {
        
        self._isRunning = false
        
        runFilterTimer?.invalidate()
        runFilterTimer = nil
        
        self.motionModel.stopMotionTracking()
        self.measurementModel.stopBeaconRanging()
    }
    
    
    // MARK: Particle Filter algorithm
    func mcl() {
        
        var particlesT = self.particles // copies particleset
        
        self.operationQueue.addOperationWithBlock({
            
//            let startTime = NSDate()
            
            // Distance measurements to Beacons
            var z_reverse = self.measurementModel.measurements.reverse()
            self.measurementModel.resetMeasurementStore()
            
            // motions
            var u_reverse = self.motionModel.latestMotions.reverse()
            self.motionModel.resetMotionStore()
            

            while !u_reverse.isEmpty && !z_reverse.isEmpty {
                
                let u_k: MotionModel.Motion = u_reverse.last!
                let z_k: MeasurementModel.Measurement = z_reverse.last!
                
                let compResult = u_k.endDate.compare(z_k.timestamp)
                
                if compResult == NSComparisonResult.OrderedAscending {
                    
                    // u_k.end <= z_k.timestamp => add to list
                    particlesT = self.integrateMotion(u_k, intoParticleSet: particlesT)
                    u_reverse.removeLast()
                    
                } else if compResult == NSComparisonResult.OrderedSame {
                  
                    particlesT = self.integrateMotion(u_k, intoParticleSet: particlesT)
                    u_reverse.removeLast()
                    // filter
                    particlesT = self.filter(particlesT, andMeasurements: z_k)
                    z_reverse.removeLast()
                    
                } else if u_k.startDate.compare(z_k.timestamp) == NSComparisonResult.OrderedAscending && z_k.timestamp.compare(u_k.endDate) != NSComparisonResult.OrderedDescending {
                    
                    // u_k.start < z_k.timestamp && z_k.timestamp < u_k.end => split up u_k
                    let motionDuration: NSTimeInterval = u_k.endDate.timeIntervalSinceDate(u_k.startDate)
                    let durationUntilZ: NSTimeInterval = z_k.timestamp.timeIntervalSinceDate(u_k.startDate)
                    
                    // create submotion
                    let d = u_k.distance * durationUntilZ/motionDuration
                    let subMotion1 = MotionModel.Motion(heading: u_k.heading, distance: d, startDate: u_k.startDate, endDate: z_k.timestamp)
                    let subMotion2 = MotionModel.Motion(heading: u_k.heading, distance: u_k.distance - d, startDate: z_k.timestamp, endDate: u_k.endDate)
                    
                    // integrate submotion 1 and filter
                    particlesT = self.integrateMotion(subMotion1, intoParticleSet: particlesT)
                    u_reverse.removeLast()
                    
                    // add submotion 2 to
                    u_reverse.append(subMotion2)
                    
                    // filter
                    particlesT = self.filter(particlesT, andMeasurements: z_k)
                    z_reverse.removeLast()
                } else {
                    particlesT = self.filter(particlesT, andMeasurements: z_k)
                    z_reverse.removeLast()
                }
            }

            
            if !u_reverse.isEmpty { // just executed if u_reverse is empty or z_reverse
                // return residual values to motion model
                self.motionModel.returnResidualMotions(u_reverse)
            }
            
            let deviceStationary = self.motionModel.isDeviceStationary
            
            // if device is Stationary => integrate sensor values, if not return them to measurement model
            if deviceStationary.stationary {
                
                while !z_reverse.isEmpty {
                    
                    let z_k = z_reverse.last!
                    
//                    if z_k.timestamp.compare(deviceStationary.timestamp) != NSComparisonResult.OrderedAscending {
                        // stationary.timestamp <= z_k.timestamp
                    
                        particlesT = self.integrateMotion(self.motionModel.stationaryMotion, intoParticleSet: particlesT)
                        particlesT = self.filter(particlesT, andMeasurements: z_k)
//                    }
                    z_reverse.removeLast()
                }
                
            } else {
                // return residual values to measurement model
                self.measurementModel.returnResidualMeasurements(z_reverse)
            }
            
            

//            let endTime = NSDate().timeIntervalSinceDate(startTime)
//            println("ParticleFilter Duration: \(endTime)")
            
            // MainThread: set particles and notify Observers
            let updateOp = NSBlockOperation(block: {
                self.startTimer()
                self.particleSet = particlesT // -> notifyObservers
            })
            NSOperationQueue.mainQueue().addOperation(updateOp)
            
        })
    }
    
    private func integrateMotion(u: MotionModel.Motion, intoParticleSet particles: [Particle]) -> [Particle] {
        
        return particles.map({p in MotionModel.sampleParticlePoseForPose(p, withMotion: u, andMap: self.map)})
    }
    
    private func filter(particles_tMinus1: [Particle], andMeasurements z: MeasurementModel.Measurement) -> [Particle] {

        // Sample motion + weight particles
        var weightedParticleSet: [(weight: Double,particle: Particle)] = []
        weightedParticleSet.reserveCapacity(self.particleSetSize)
        
        for particle in particles_tMinus1 {
            
            var w: Double = MeasurementModel.weightParticle(particle, withDistanceMeasurements: z.z, andMap: self.map)
            if w > 0 {
                // commute weights
                if weightedParticleSet.count > 1 {
                    w += weightedParticleSet.last!.0 // add weigt of predecessor
                }
                weightedParticleSet += [(weight: w, particle: particle)]
            }
        }
        

        // Histogram to measure particle diversity
        var particleHistogram = [Int](count: weightedParticleSet.count, repeatedValue: 0)
        var differentParticleCount = 0

        // Particle set mean
        var weightedParticleSetMean: (x: Double, y: Double) = (0.0, 0.0)
        var weightSum = 0.0
        
        // roulette
        var particles_t: [Particle] = []
        particles_t.reserveCapacity(weightedParticleSet.count)
        
        
        var logCount_addedRandomParticleCount = 0
        
        while particles_t.count < self.particleSetSize {

            let particleDiversity: Double = Double(differentParticleCount) / Double(particleHistogram.count)
            
            // spezifies until which count particles can be drawn without checking the diversity
            let insertLevel =  (self.particleSetSize - Int(Double(self.particleSetSize) * self.desiredParticleDiversity))
            
            
            if particleDiversity >= self.desiredParticleDiversity || particles_t.count < insertLevel {
            
                // draw particle with probability
                if let last = weightedParticleSet.last {
                    let random = Random.rand_uniform() * last.weight
                    
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
                    
                    // add particle to new set
                    particles_t.append(particle)
                    
                    particleHistogram[m] += 1
                    if particleHistogram[m] == 1 {
                        ++differentParticleCount
                    }
                    
                    // calc weighted particleSetMean
                    weightedParticleSetMean.x += particle.x * weight
                    weightedParticleSetMean.y += particle.y * weight
                    weightSum += weight

                }
                
            } else {
                // insert random particle
                particles_t.append(generateRandomParticle())
                
                particleHistogram.append(1)
                ++differentParticleCount
                ++logCount_addedRandomParticleCount
            }
        }
        
        if weightSum > 0 {
            self.weightedParticleSetMean = (x: weightedParticleSetMean.x/weightSum, y: weightedParticleSetMean.y/weightSum)
            self.estimatedPath.append(Pose(x: self.weightedParticleSetMean.x, y: self.weightedParticleSetMean.y, theta: 0.0))
        }
        
        let logStmt = "ParticleDiversity: \(Double(differentParticleCount) / Double(particleHistogram.count)) (\(logCount_addedRandomParticleCount) random particles), ParticleWeightSum: \(weightSum)"
        
        println(logStmt)
        Logger.sharedInstance.log(message: logStmt)
        
        return particles_t
    }
    
    
    // MARK: Particle generation
    
    private func generateParticlesAroundBeacons(beacons: [Beacon]) -> [Particle] {
        
        var particles = [Particle]()
        if let b = beacons.first {
//        for b in beacons {
            if let landmark = self.map.landmarks[b.identifier] {
                let xMin = max(0.0, landmark.x - (b.accuracy * 0.5))
                let xMax = min(self.map.size.x, landmark.x + (b.accuracy * 0.5))
                
                let yMin = max(0.0, landmark.y - (b.accuracy * 0.5))
                let yMax = min(self.map.size.y, landmark.y + (b.accuracy * 0.5))
                
//                let size:Int = Int(ceil(Double(self.particleSetSize) / Double(beacons.count)))
                let size = self.particleSetSize
                
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