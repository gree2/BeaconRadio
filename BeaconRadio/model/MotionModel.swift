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
        let startDate: NSDate
        let endDate: NSDate
        
        init(heading: Double, distance:Double, startDate: NSDate, endDate: NSDate) {
            self.heading = heading
            self.distance = distance
            self.startDate = startDate
            self.endDate = endDate
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
    
    
    private var _isDeviceStationary = (timestamp: NSDate(), stationary: true)
    var isDeviceStationary: (timestamp: NSDate, stationary: Bool) {
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
    
    var latestMotions: [Motion] {
        get {
            return self.motionStore_pf
        }
    }
    
    var stationaryMotion: Motion {
        get {
            return Motion(heading: self.currentHeading(), distance: 0.0, startDate: NSDate(), endDate: NSDate())
        }
    }
    
    func resetMotionStore() {
        self.motionStore_pf.removeAll(keepCapacity: true)
    }
    
    func returnResidualMotions(u: [Motion]) {
        self.motionStore_pf = (self.motionStore_pf + u).sorted({$0.startDate.compare($1.startDate) == NSComparisonResult.OrderedAscending})
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
        
        let isStationary = !(!stationary && confidence.rawValue >= CMMotionActivityConfidence.Low.rawValue)
        
        if isStationary != self._isDeviceStationary.stationary { // Just set if changes => timestamp is kept if nothing changes
            self._isDeviceStationary = (timestamp: start, stationary: isStationary)
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
            motions.append(Motion(heading: currentHeading(), distance: distance, startDate: start, endDate: end))
        } else {
            for (index, heading) in enumerate(headings) {
                
                var startDate: NSDate = start
                var endDate: NSDate = end
                
                if index == 0 && headings.count > 1 { // first heading use start date and next heading
                    endDate = headings[index+1].timestamp
                    startDate = start
                } else if index > 0 && headings.count > index+1 { // successor: yes
                    endDate = headings[index+1].timestamp
                    startDate = heading.timestamp
                } else if index > 0 { // successor: no
                    endDate = end
                    startDate = heading.timestamp
                }
                
                let headingDuration = endDate.timeIntervalSinceDate(startDate)
                
                let d = distance * headingDuration/totalDuration
                
                motions.append(Motion(heading: heading.heading, distance: d, startDate: startDate, endDate: endDate))
            }
        }
        
        return motions
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
    
    
    // MARK: Sample Motion Model
    class func sampleParticlePoseForPose(p: Pose, withMotions u: [Motion], andMap m: Map) -> Pose {
        
        var pose = p
        
        for u_t in u {
            pose = sampleParticlePoseForPose(pose, withMotion: u_t, andMap: m)
        }
        
        return pose
    }
    
    class func sampleParticlePoseForPose(p: Pose, withMotion u: Motion, andMap m: Map) -> Pose {
        var pose = p
        var i = 0
        
        do {
            var sigma_rot = Angle.deg2Rad(10.0) // degree
            //            let sigma_trans = 0.0971 * u_t.distance + 1.445 //0.068 * u_t.distance + 2.1559
            var sigma_trans = 0.1 * u.distance
            
            if u.distance == 0.0 {
                sigma_rot = M_PI
                sigma_trans = 0.5
            }
            
            var h = u.heading - Random.sample_normal_distribution(sigma_rot)
            let d = u.distance - Random.sample_normal_distribution(sigma_trans)
            
            var xDiff = cos(h) * d
            var yDiff = sin(h) * d
            
            pose = Pose(x: p.x + xDiff, y: p.y + yDiff, theta: h)
            
        } while (!m.isCellFree(x: pose.x, y: pose.y) && i++ < 10)
        
        return pose
    }

}