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


class MotionModel: MotionTrackerDelegate {
    
    struct Motion {
        let heading: Double
        let distance: Double
        
        init(heading: Double, distance:Double) {
            self.heading = heading
            self.distance = distance
        }
    }
    
    private let motionTracker = MotionTrackerFactory.motionTracker
    private let map: Map
    
    private var latestHeading: (timestamp: NSDate, heading: Double)?
    private var headingStore: [(timestamp: NSDate, heading: Double)] = []
    private var latestDistanceMeasurement: (timestamp: NSDate, distance: Double)?
    private var motionStore_pf = [Motion]() // particle filter
    private var motionStore = [Motion]()
    
    private var poseStore = [Pose]()
    private var startPose: Pose
    
    
    private var _isDeviceStationary: Bool = true
    var isDeviceStationary: Bool {
        get {
            return self._isDeviceStationary
        }
    }
    
    
    init(map: Map) {
        self.map = map
//        self.startPose = Pose(x: 1.93, y: 1.24, theta: 0.0) // x = 0.38 + 0.55 + 1.0 = 1.93, y = 0.04 + 1.2 = 1.24 (Türe VR)
        self.startPose = Pose(x: 7.93, y: 1.24, theta: 0.0) // x = 0.38 + 0.55 + 7.0 = 1.93, y = 0.04 + 1.2 = 1.24 (Fenster VL)
    }
    
    func startMotionTracking() {
        self.motionTracker.startMotionTracking(self)
    }
    
    func stopMotionTracking() {
        self.motionTracker.stopMotionTracking() // TODO: Delete maybe all old data?
        
        for p in poseStore {
            Logger.sharedInstance.log(message: "[MotionPose] x:\(p.x), y: \(p.y)")
        }
        Logger.sharedInstance.save2File()
    }
    
    // MARK: Sample Motion Model
    class func sampleParticlePoseForPose(p: Pose, withMotions u: [Motion], andMap m: Map) -> Pose {
        
        var pose: Pose = p
        
        if !u.isEmpty {
            var i = 0
            
            do {
                var xDiff = 0.0
                var yDiff = 0.0
                
                var h = 0.0
                
                for u_t in u {
                    var sigma_rot = Angle.deg2Rad(10.0) // degree
//                    let sigma_trans = 0.0971 * u_t.distance + 1.445 //0.068 * u_t.distance + 2.1559
                    var sigma_trans = 0.1 * u_t.distance
                    
                    if u_t.distance == 0.0 {
                        sigma_rot = M_PI
                        sigma_trans = 0.5
                    }
                    
                    h = u_t.heading - Random.sample_normal_distribution(sigma_rot)
                    let d = u_t.distance - Random.sample_normal_distribution(sigma_trans)
                    
                    xDiff += cos(h) * d
                    yDiff += sin(h) * d
                }
                
                pose = Pose(x: p.x + xDiff, y: p.y + yDiff, theta: h)
                
            } while (!m.isCellFree(x: pose.x, y: pose.y) && i++ < 5)
        }
        
        return pose
    }
    
    var latestMotions: [Motion] {
        get {
            if self.motionStore_pf.isEmpty {
                return [Motion(heading: self.currentHeading(), distance: 0.0)]
            } else {
                return self.motionStore_pf
            }
        }
    }
    
    func resetMotionStore() {
        self.motionStore_pf.removeAll(keepCapacity: true)
    }
    
    
    // MARK: Motion based pose estimation
    private func computeNewPoseEstimation() {
        
        var xDiff = 0.0
        var yDiff = 0.0
        
        var heading = 0.0
        
        for u_t in self.motionStore {
            xDiff += cos(u_t.heading) * u_t.distance
            yDiff += sin(u_t.heading) * u_t.distance
            
            heading = u_t.heading
        }
        
        let lastPose = self.lastPoseEstimation
        
        poseStore.append(Pose(x: lastPose.x + xDiff, y: lastPose.y + yDiff, theta: heading))
        
        self.motionStore.removeAll(keepCapacity: true)
    }
    
    var lastPoseEstimation: Pose {
        get {
            if let last = self.poseStore.last {
                return last
            } else {
                let p = self.startPose
                self.poseStore.append(p)
                
                return p
            }
        }
    }
    
    var estimatedPath: [Pose] {
        get {
            return self.poseStore
        }
    }

    
    // MARK: MotionTrackerDelegate
    func motionTracker(tracker: IMotionTracker, didReceiveHeading heading: Double, withTimestamp ts: NSDate) {
        
        let mapBasedHeading: Double = heading - self.map.mapOrientation
        
        let tupel: (timestamp: NSDate, heading: Double) = (ts, Angle.compassDeg2UnitCircleRad(mapBasedHeading))
        
        self.headingStore.append(tupel)
    }
    
    func motionTracker(tracker: IMotionTracker, didReceiveDistance d: Double, withStartDate start: NSDate, andEndDate end: NSDate) {
        
        var motions = [Motion]()
        
        if let last = self.latestDistanceMeasurement {
            
            if d > last.distance { // same distance ist sometimes sent multiple times with different timestamp
                motions = computeMotionsByIntegratingHeadingIntoDistance(d - last.distance, forStartTime: last.timestamp, andEndTime: end)
                resetHeadingStore()
            }
            
        } else {
            motions = computeMotionsByIntegratingHeadingIntoDistance(d, forStartTime: start, andEndTime: end)
        }
        
        self.motionStore += motions
        self.motionStore_pf += motions
        
        self.latestDistanceMeasurement = (end, d)
        computeNewPoseEstimation()
    }
    
    func motionTracker(tracker: IMotionTracker, didReceiveMotionActivityData stationary: Bool, withConfidence confidence: CMMotionActivityConfidence, andStartDate start: NSDate) {
        if !stationary && confidence.rawValue >= CMMotionActivityConfidence.Low.rawValue {
            self._isDeviceStationary = false
        } else {
            self._isDeviceStationary = true
        }
    }
    
    // MARK: Motion calculation
    private func computeMotionsByIntegratingHeadingIntoDistance(distance: Double, forStartTime start: NSDate, andEndTime end: NSDate) -> [Motion] {
        
        let headings = self.headingStore.filter({h in (h.timestamp.compare(start) != NSComparisonResult.OrderedAscending && h.timestamp.compare(end) != NSComparisonResult.OrderedDescending)})
        //FIXME headings filter
        
//        if let first = headings.first {
//            if first.timestamp.compare(start) == NSComparisonResult.OrderedDescending && // suche heading davor und setzte startdate auf start
//        }
        
        let totalDuration = end.timeIntervalSinceDate(start)
        
        
        var motions = [Motion]()
        
        if headings.isEmpty {
            
            let duration = end.timeIntervalSinceDate(start)
            
            motions.append(computeMotionWithHeading(currentHeading(), distance: distance, headingDuration: duration, totalDuration: duration))
        }
        
        // implicit else-Block
        for (index, heading) in enumerate(headings) {
            
            var headingDuration = 0.0
            
            if index == 0 && headings.count > 1 { // first heading use start date and next heading
                headingDuration = headings[index+1].timestamp.timeIntervalSinceDate(start)
            } else if index == 0 && headings.count == 1 { // the only heading for distance
                headingDuration = end.timeIntervalSinceDate(start)
            } else if index > 0 && headings.count > index+1 { // successor: yes
                headingDuration = headings[index+1].timestamp.timeIntervalSinceDate(heading.timestamp)
            } else if index > 0 { // successor: no
                headingDuration = end.timeIntervalSinceDate(heading.timestamp)
            }
            
            let magneticHeading = heading.heading
            
            motions.append(computeMotionWithHeading(magneticHeading, distance: distance, headingDuration: headingDuration, totalDuration: totalDuration))
        }
        
        return motions
    }
    
    private func computeMotionWithHeading(heading: Double, distance: Double, headingDuration: NSTimeInterval, totalDuration: NSTimeInterval) -> Motion {
        let d = distance * headingDuration/totalDuration
        return Motion(heading: heading, distance: d)
    }
    
    private func currentHeading() -> Double {
        var heading = 0.0
        if let last = self.headingStore.last {
            heading = last.heading
        } else if let last = self.latestHeading {
            heading = last.heading
        }
        return heading
    }
    
    private func resetHeadingStore() {
        if let last = self.headingStore.last {
            self.latestHeading = last
            self.headingStore.removeAll(keepCapacity: true)
        }
    }

}