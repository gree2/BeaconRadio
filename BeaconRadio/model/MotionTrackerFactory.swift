//
//  MotionTrackerFactory.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 24/11/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation
import CoreMotion


class MotionTrackerFactory {

private class var _motionTracker: IMotionTracker? {

    struct Static {
        static var instance: IMotionTracker?
        static var token: dispatch_once_t = 0
        static let simulation = Settings.sharedInstance.simulation
    }
    
    dispatch_once(&Static.token) {
        
        if Static.simulation {
            Static.instance = MotionTrackerSimulator()
        } else {
            Static.instance = MotionTracker()
        }
        
    }
        return Static.instance!
    }

    class var motionTracker: IMotionTracker {
        get {
            return _motionTracker!
        }
    }
}

protocol IMotionTracker {
    init()
    func startMotionTracking(delegate: MotionTrackerDelegate)
    func stopMotionTracking()
}

protocol MotionTrackerDelegate {
    func motionTracker(tracker: IMotionTracker, didReceiveHeading heading: Double, withTimestamp ts: NSDate)
    func motionTracker(tracker: IMotionTracker, didReceiveDistance d: Double, withStartDate start: NSDate, andEndDate end: NSDate)
    func motionTracker(tracker: IMotionTracker, didReceiveMotionActivityData stationary: Bool, withConfidence confidence: CMMotionActivityConfidence, andStartDate start: NSDate)
}
