//
//  MotionModel.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 06/11/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation
import CoreMotion
import CoreLocation


class MotionModel: NSObject, CLLocationManagerDelegate {
    private var operationQueue: NSOperationQueue?
//    var operationQueue: NSOperationQueue = {
//        let queue = NSOperationQueue()
//        queue.qualityOfService = NSQualityOfService.Background
//        
//        return queue
//        }()
    private var isTracking: Bool = false
    private lazy var pedometer = CMPedometer()
    private lazy var stepcounter = CMStepCounter()
    private lazy var motionactivity = CMMotionActivityManager()
    private lazy var deviceMotion = CMMotionManager()
    private lazy var locationManager = CLLocationManager()

    
    // TODO: Lock stores
    private var latestHeading: CLHeading?
    private var headingStore: [CLHeading] = []
    private var latestPedometerData: CMPedometerData?
    private var pedometerStore: [CMPedometerData] = []
    // TODO: Lock stores
    
    
    private var poseStore: [Pose] = []
    
    var estimatedPath: [Pose] {
        get {
            var poses: [Pose] = []
            poses.reserveCapacity(self.poseStore.count)
            
            for p in self.poseStore {
                poses.append(p) // copies struct
            }
            return poses
        }
    }

    typealias Motion = Pose
    
    
    override init () {
        super.init()
        if !CMPedometer.isDistanceAvailable() {
            println("[ERROR] CMPedometer: Distance NOT available.")
        }
        
        if !CMPedometer.isStepCountingAvailable() {
            println("[ERROR] CMStepCounter: Stepcounting NOT available.")
        }
        
        if !CMMotionActivityManager.isActivityAvailable() {
            println("[ERROR] CMMotionActivityManager: MotionActivity NOT available.")
        }
        
        self.deviceMotion.deviceMotionUpdateInterval = 1.0
        
        // CLLocationManager authorization request
        self.locationManager.delegate = self
        self.locationManager.headingFilter = 5.0
        self.headingStore.reserveCapacity(10)
        
        if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.Restricted ||
            CLLocationManager.authorizationStatus() == CLAuthorizationStatus.Denied {
            
            println("[ERROR] CLLocationManager: Authorization status \(CLLocationManager.authorizationStatus())")
                
        } else if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.NotDetermined {
            self.locationManager.requestWhenInUseAuthorization() // requestAlwaysAuthorization
        }
    }
    
    func startMotionTracking(operationQueue: NSOperationQueue) {
        self.operationQueue = operationQueue
        
        let authStatus = CLLocationManager.authorizationStatus()
        
        if  !self.isTracking && CLLocationManager.locationServicesEnabled() &&
            (authStatus == CLAuthorizationStatus.Authorized || authStatus == CLAuthorizationStatus.AuthorizedWhenInUse) {
            
            if CLLocationManager.headingAvailable() {
                self.locationManager.startUpdatingHeading()
            }
            
            if CMPedometer.isDistanceAvailable() {
                self.pedometer.startPedometerUpdatesFromDate(NSDate(), withHandler: { data, error in
                    if error != nil {
                        println("[ERROR] CMPedometer: \(error.description)")
                    } else {
                        
                        let operation = NSBlockOperation(block: {
                            self.pedometerStore.append(data)
                        })
                        
                        operationQueue.addOperation(operation)
                    }
                })
            }
            
            if CMStepCounter.isStepCountingAvailable() {
                self.stepcounter.startStepCountingUpdatesToQueue(operationQueue, updateOn: 1, withHandler: {numberOfSteps, timestamp, error in
                    if error != nil {
                        println("[ERROR] CMStepCounter: \(error.description)")
                    } else {
                        // TODO
                    }
                })
            }
            
            if CMMotionActivityManager.isActivityAvailable() {
                self.motionactivity.startActivityUpdatesToQueue(operationQueue, withHandler: {activity in
                    // TODO (activity and confidence)
                    
                })
            }
                
            self.deviceMotion.startDeviceMotionUpdatesToQueue(operationQueue, withHandler: {motion, error in
                if error != nil {
                    println("[ERROR] CMDeviceMotion: \(error.description)")
                } else {
                    // TODO
                    //println("DeviceMotion: \(motion.attitude.description)")
                }
                
            })
        }
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if !((status == CLAuthorizationStatus.Authorized || status == CLAuthorizationStatus.AuthorizedWhenInUse) && isTracking) {
            self.stopMotionTracking()
            println("[ERROR] CLLocationManager: Authorization status \(CLLocationManager.authorizationStatus())")
        }
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateHeading newHeading: CLHeading!) {
        // TODO
        //println("Heading: \(newHeading.description)")
        
        
        let operation = NSBlockOperation(block: {
            self.headingStore.append(newHeading)
        })
        if let operationQueue = self.operationQueue {
            operationQueue.addOperation(operation)
        }
    }

    func stopMotionTracking() {
        if isTracking {
            self.pedometer.stopPedometerUpdates()
            self.stepcounter.stopStepCountingUpdates()
            self.motionactivity.stopActivityUpdates()
            self.locationManager.stopUpdatingHeading()
        }
    }
    
    
    // MARK: Motion based pose estimation
    
    func lastPoseEstimation() -> Pose {
        if let last = self.poseStore.last {
            return last
        } else {
            return Pose(x: 0, y: 0, theta: currentHeading())
        }
    }
    
    func computeNewPoseEstimation() -> Pose {
        var pose: Pose
        
        let pedometerMotion = estimatedMotionFromPedometerSinceLastCall()
        
        if let lastPose = self.poseStore.last {
            pose = Pose(x: lastPose.x + pedometerMotion.x, y: lastPose.y + pedometerMotion.y, theta: pedometerMotion.theta)
        } else {
            pose = pedometerMotion
        }
        self.poseStore.append(pose)
        
        // should maybe put into operationqueue
        resetHeadingStore()
        resetPedometerStore()
        
        return pose
    }
    
    private func estimatedMotionFromPedometerSinceLastCall() -> Motion {
     
        var motion = Motion(x: 0, y: 0, theta: 0)
        
        switch self.pedometerStore.count {
        case 0:
            motion = Motion(x: 0, y: 0, theta: currentHeading())
        case 1:
            
            let pedometerData = self.pedometerStore.last!
            var startDate: NSDate
            
            if let latest = self.latestPedometerData {
                startDate = latest.endDate
            } else {
                startDate = pedometerData.startDate
            }
            
            motion = computeMotionByIntegratingHeadingIntoDistance(Double(pedometerData.distance), forStartTime: startDate, andEndTime: pedometerData.endDate)
        default:
            
            for var i = 0; i < self.pedometerStore.count; ++i {
                
                let pData_t = self.pedometerStore[i]
                
                var motionPart: Motion
                
                if i == 0 && self.latestPedometerData != nil {
                    
                    let pData_tMinus1:CMPedometerData = self.latestPedometerData!
                    
                    motionPart = computeMotionByIntegratingHeadingIntoDistance(
                        Double(pData_t.distance) - Double(pData_tMinus1.distance),
                        forStartTime: pData_tMinus1.endDate,
                        andEndTime: pData_t.endDate)
                    
                } else if i == 0 && self.latestPedometerData == nil {
                    
                    motionPart = computeMotionByIntegratingHeadingIntoDistance(
                        Double(pData_t.distance),
                        forStartTime: pData_t.startDate,
                        andEndTime: pData_t.endDate)
                    
                } else {
                    
                    let pData_tMinus1 = self.pedometerStore[i-1]
                    motionPart = computeMotionByIntegratingHeadingIntoDistance(
                        Double(pData_t.distance) - Double(pData_tMinus1.distance),
                        forStartTime: pData_tMinus1.endDate,
                        andEndTime: pData_t.endDate)
                }
                
                motion = Motion(x: motion.x + motionPart.x, y: motion.y + motionPart.y, theta: motionPart.theta)
            }
        }
        
        return motion
    }
    
    private func computeMotionByIntegratingHeadingIntoDistance(distance: Double, forStartTime start: NSDate, andEndTime end: NSDate) -> Motion {
        
        let headings = self.headingStore.filter({h in (h.timestamp.compare(start) != NSComparisonResult.OrderedAscending && h.timestamp.compare(end) != NSComparisonResult.OrderedDescending)})
        
        let totalDuration = end.timeIntervalSinceDate(start)
        
        var motion: Motion = Motion(x: 0, y: 0, theta: currentHeading())
        
        if headings.isEmpty {
            
            let duration = end.timeIntervalSinceDate(start)
            
            motion = computeMotionWithHeading(currentHeading(), distance: distance, headingDuration: duration, totalDuration: duration)
        }
        
        // implicit else-Block
        for heading in headings {
            let headingDuration = heading.timestamp.timeIntervalSinceDate(start)
            let magneticHeading = Angle.compassDeg2UnitCircleRad(heading.magneticHeading)
            
            let motionDiff = computeMotionWithHeading(magneticHeading, distance: distance, headingDuration: headingDuration, totalDuration: totalDuration)
            motion = Motion(x: motion.x + motionDiff.x, y: motion.y + motionDiff.y, theta: motionDiff.theta)
        }
        return motion
    }
    
    private func computeMotionWithHeading(heading: Double, distance: Double, headingDuration: NSTimeInterval, totalDuration: NSTimeInterval) -> Motion {
        var xDiff = abs(cos(heading) * (distance * headingDuration/totalDuration))
        var yDiff = abs(sin(heading) * (distance * headingDuration/totalDuration))
        
        if heading >= M_PI_2 && heading < M_PI {
            yDiff *= -1
        } else if heading >= M_PI && heading < (2/3 * M_PI) {
            xDiff *= -1
            yDiff *= -1
        } else if heading >= (2/3 * M_PI) && heading < (2 * M_PI) {
            xDiff *= -1
        }
        return Motion(x: xDiff, y: yDiff, theta: heading)
    }
    
    private func currentHeading() -> Double {
        var heading = 0.0
        if let last = self.headingStore.last {
            heading = Angle.compassDeg2UnitCircleRad(last.magneticHeading)
        } else if let last = self.latestHeading {
            heading = Angle.compassDeg2UnitCircleRad(last.magneticHeading)
        }
        return heading
    }
    
    private func resetPedometerStore() {
        if let last = self.pedometerStore.last {
            self.latestPedometerData = last
            self.pedometerStore.removeAll(keepCapacity: true)
        }
    }
    
    private func resetHeadingStore() {
        if let last = self.headingStore.last {
            self.latestHeading = last
            self.headingStore.removeAll(keepCapacity: true)
        }
    }
    
    
    
    // MARK: Sample Motion Model
    
    class func sampleParticlePoseForPose(p: Pose, withMotionFrom u_tMinus1: Pose, to u_t: Pose) -> Pose {
        let d_rot_1 = atan2(u_t.y - u_tMinus1.y, u_t.x - u_tMinus1.x) - u_tMinus1.theta
        let d_trans = sqrt( pow((u_tMinus1.x - u_t.x), 2) + pow((u_tMinus1.y - u_t.y), 2) )
        let d_rot_2 = u_t.theta

        
        let sigma_rot = Angle.deg2Rad(5.0) // degree
        let sigma_trans = 0.1 * d_trans // m => 1m bei 10m distance, 2m bei 20m distance, ...

        
        let d2_rot_1 = d_rot_1 - Random.sample_normal_distribution(sigma_rot)
        let d2_trans = d_trans - Random.sample_normal_distribution(sigma_trans)
        let d2_rot_2 = d_rot_2 - Random.sample_normal_distribution(sigma_rot)
        
        let x_t = p.x + d2_trans * cos(p.theta + d2_rot_1)
        let y_t = p.y + d2_trans * sin(p.theta + d2_rot_1)
        let theta_t = d2_rot_2
        
        return Pose(x: x_t, y: y_t, theta: theta_t)
    }
    
    /*
    * @see: Probabilistic Robots, S. Thrun et al, Page 136 (sample_motion_model_odometry)
    */
//    class func sampleParticlePoseForPose(p: Pose, withMotionFrom u_tMinus1: Pose, to u_t: Pose) -> Pose {
//        
//        // alpha_1, _2, _3, _4
//        let alpha = [0.1, 0.1, 0.1, 0.1]
//        
//        let d_rot_1 = atan2(u_t.y - u_tMinus1.y, u_t.x - u_tMinus1.x) - u_tMinus1.theta
//        let d_trans = sqrt( pow((u_tMinus1.x - u_t.x), 2) + pow((u_tMinus1.y - u_t.y), 2) )
//        let d_rot_2 = u_t.theta - u_tMinus1.theta - d_rot_1
//        
//        
//        let d2_rot_1 = d_rot_1 - Random.sample_normal_distribution(alpha[0] * abs(d_rot_1) + alpha[1] * d_trans)
//        let d2_trans = d_trans - Random.sample_normal_distribution( alpha[2] * d_trans + alpha[3] * (abs(d_rot_1) + abs(d_rot_2)) )
//        let d2_rot_2 = d_rot_2 - Random.sample_normal_distribution( alpha[0] * abs(d_rot_2) + alpha[1] * d_trans )
//        
//        let x_t = p.x + d2_trans * cos(p.theta + d2_rot_1)
//        let y_t = p.y + d2_trans * sin(p.theta + d2_rot_1)
//        let theta_t = p.theta + d2_rot_1 + d2_rot_2
//        
//        return Pose(x: x_t, y: y_t, theta: theta_t)
//    }
    
    /*
    * @see: Probabilistic Robots, S. Thrun et al, Page 141 (sample_motion_model_with_map)
    */
    class func sampleParticlePoseForPose(p: Pose, withMotionFrom u_tMinus1: Pose, to u_t: Pose, and map: Map) -> Pose {
        
        var i = 0
        var free = false
        var pose: Pose
        
        do {
            pose = sampleParticlePoseForPose(p, withMotionFrom: u_tMinus1, to: u_t)
            free = map.isCellFree(pose.x, y: pose.y)
        } while (!free && i++ <= 10)
        
        //println("Motion: \(u_tMinus1.description())\n-> \(u_t.description())")
        //println("Pose: \(p.description())\n-> \(pose.description())")
        
        return pose
    }
}