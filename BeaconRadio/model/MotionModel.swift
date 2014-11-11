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
    private lazy var operationQueue: NSOperationQueue = {
        let queue = NSOperationQueue()
        queue.qualityOfService = NSQualityOfService.Background
        
        return queue
        }()
    private var isTracking: Bool = false
    private lazy var pedometer = CMPedometer()
    private lazy var stepcounter = CMStepCounter()
    private lazy var motionactivity = CMMotionActivityManager()
    private lazy var deviceMotion = CMMotionManager()
    private lazy var locationManager = CLLocationManager()

    
    private var headingStore: [CLHeading] = []
    private var pedometerStore: [CMPedometerData] = []

    struct MotionData {
        let x: Int // cm
        let y: Int // cm
        let orientation: UInt // 0 <= degree 360
        
        init(x: Int, y: Int, orientation: UInt) {
            
            self.x = x
            self.y = y
            
            if 0 < orientation  && orientation < 360 {
                self.orientation = orientation
            } else {
                self.orientation = 0
            }
        }
        
        func description() -> String {
            return "Motion with x: \(self.x), y: \(self.y), orientation: \(self.orientation)"
        }
    }
    
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
    
    func startMotionTracking() {
        
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
                        self.pedometerStore.append(data)
                    }
                })
            }
            
            if CMStepCounter.isStepCountingAvailable() {
                self.stepcounter.startStepCountingUpdatesToQueue(self.operationQueue, updateOn: 1, withHandler: {numberOfSteps, timestamp, error in
                    if error != nil {
                        println("[ERROR] CMStepCounter: \(error.description)")
                    } else {
                        // TODO
                    }
                })
            }
            
            if CMMotionActivityManager.isActivityAvailable() {
                self.motionactivity.startActivityUpdatesToQueue(self.operationQueue, withHandler: {activity in
                    // TODO (activity and confidence)
                    
                })
            }
                
            self.deviceMotion.startDeviceMotionUpdatesToQueue(self.operationQueue, withHandler: {motion, error in
                if error != nil {
                    println("[ERROR] CMDeviceMotion: \(error.description)")
                } else {
                    // TODO
                    //println("DeviceMotion: \(motion.attitude.description)")
                }
                
            })
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
    
    func motionDiffToLastMotion() -> MotionData {
     
        switch self.pedometerStore.count {
        case 0:
            return MotionData(x: 0, y: 0, orientation: currentHeading()) // TODO
        case 1:
            let pData = self.pedometerStore.last!
            return computeMotionForDistance(Double(pData.distance), forStartTime: pData.startDate, andEndTime: pData.endDate)
        default:
            
            var motion: MotionData = MotionData(x: 0, y: 0, orientation: 0)
            
            for var i = 1; i < self.pedometerStore.count; ++i {
                let pData_tMinus1 = self.pedometerStore[i-1]
                let pData_t = self.pedometerStore[i]
                
                let distance = Double(pData_t.distance) - Double(pData_tMinus1.distance)
                
                let result = computeMotionForDistance(distance, forStartTime: pData_tMinus1.endDate, andEndTime: pData_t.endDate)
                
                motion = MotionData(x: motion.x + result.x, y: motion.y + result.y, orientation: result.orientation)
            }
            
            return motion
        }
    }
    
    private func computeMotionForDistance(distance: Double, forStartTime start: NSDate, andEndTime end: NSDate) -> MotionData {
        
        let headings = self.headingStore.filter({h in (h.timestamp.compare(start) != NSComparisonResult.OrderedAscending && h.timestamp.compare(end) != NSComparisonResult.OrderedDescending)})
        
        let totalDuration = end.timeIntervalSinceDate(start)
        
        var motion = MotionData(x: 0, y: 0, orientation: 0)
        
        for heading in headings {
            let headingDuration = heading.timestamp.timeIntervalSinceDate(start)
            
            var xDiff = abs(cos(heading.magneticHeading) * (distance * headingDuration/totalDuration))
            var yDiff = abs(sin(heading.magneticHeading) * (distance * headingDuration/totalDuration))
            
            if heading.magneticHeading >= 90 && heading.magneticHeading < 180 {
                yDiff *= -1
            } else if heading.magneticHeading >= 180 &&  heading.magneticHeading < 270 {
                xDiff *= -1
                yDiff *= -1
            } else if heading.magneticHeading >= 270 &&  heading.magneticHeading < 360 {
                xDiff *= -1
            }
            
            motion = MotionData(x: motion.x + Int(xDiff*100.0), y: motion.y + Int(yDiff*100.0), orientation: UInt(heading.magneticHeading))
        }
        return motion
    }
    
    private func currentHeading() -> UInt {
        if let last = self.headingStore.last {
            return UInt(last.magneticHeading)
        }
        return 0
    }
    
    // MARK: CLLocationManagerDelegate protocol
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if !((status == CLAuthorizationStatus.Authorized || status == CLAuthorizationStatus.AuthorizedWhenInUse) && isTracking) {
            self.stopMotionTracking()
            println("[ERROR] CLLocationManager: Authorization status \(CLLocationManager.authorizationStatus())")
        }
    }

    func locationManager(manager: CLLocationManager!, didUpdateHeading newHeading: CLHeading!) {
        // TODO
        //println("Heading: \(newHeading.description)")
        self.headingStore.append(newHeading)
    }
}