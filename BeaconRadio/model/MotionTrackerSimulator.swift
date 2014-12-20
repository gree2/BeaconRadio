//
//  MotionTrackerSimulator.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 24/11/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation
import CoreMotion

class MotionTrackerSimulator: IMotionTracker, DataPlayerDelegate {

    private var delegate: MotionTrackerDelegate?
    
//    private let headingPlayer = DataPlayer()
    private let deviceMotionPlayer = DataPlayer()
    private let pedometerPlayer = DataPlayer()
    private let activityPlayer = DataPlayer()
    // further players currently not beeing used
    
    required init() {
        
    }
    
    func startMotionTracking(delegate: MotionTrackerDelegate) {
        self.delegate = delegate
        
        let settings = Settings.sharedInstance
        
//        self.headingPlayer.load(dataStoragePath: Util.pathToLogfileWithName("\(settings.simulationDataPrefix)_Heading.csv")!, error: nil)
        self.deviceMotionPlayer.load(dataStoragePath: Util.pathToLogfileWithName("\(settings.simulationDataPrefix)_DeviceMotion.csv")!, error: nil)
        self.pedometerPlayer.load(dataStoragePath: Util.pathToLogfileWithName("\(settings.simulationDataPrefix)_Pedometer.csv")!, error: nil)
        self.activityPlayer.load(dataStoragePath: Util.pathToLogfileWithName("\(settings.simulationDataPrefix)_Activity.csv")!, error: nil)
        
//        self.headingPlayer.playback(self)
        self.deviceMotionPlayer.playback(self)
        self.pedometerPlayer.playback(self)
        self.activityPlayer.playback(self)
    }
    
    func stopMotionTracking() {
        
    }
    
    
    // MARK: DataPlayerDelegate protocol
    func dataPlayer(player: DataPlayer, handleData data: [[String:String]]) {
        
//        if player === self.headingPlayer {
//            handleHeadingData(data)
//        } else
        if player === self.deviceMotionPlayer {
            handleDeviceMotionData(data)
        } else if player === self.pedometerPlayer {
            handlePedometerData(data)
        } else if player === self.activityPlayer {
            handleActivityData(data)
        }
    }
    
//    private func handleHeadingData(data: [[String:String]]) {
//        
//        for d in data {
//            let heading: Double = NSString(string: d["magneticHeading"]!).doubleValue
//            
//            let timeInterval: Double = NSString(string: d["ts"]!).doubleValue
//            let timestamp: NSDate = self.headingPlayer.convertRelativeDateToAbsolute(timeInterval) // relative timestamp to playerstart
//            
//            self.delegate?.motionTracker(self, didReceiveHeading: heading, withTimestamp: timestamp)
//        }
//    }
    
    private func handleDeviceMotionData(data: [[String:String]]) {
        
        for d in data {
            
            let timeInterval: Double = NSString(string: d["ts"]!).doubleValue
            let timestamp: NSDate = self.deviceMotionPlayer.convertRelativeDateToAbsolute(timeInterval) // relative timestamp to playerstart
            
            let m12: Double = NSString(string: d["m12"]!).doubleValue
            let m22: Double = NSString(string: d["m22"]!).doubleValue
            
            // http://stackoverflow.com/questions/9341223/how-can-i-get-the-heading-of-the-device-with-cmdevicemotion-in-ios-5/11299471#11299471
            if m22 != 0 && m12 != 0 {
                let heading = (M_PI + atan2(m22, m12)) * 180.0 / M_PI // in compass deg
                
                //let heading = (motion.attitude.yaw + M_PI) % (2 * M_PI) // yaw: -PI/2 = North, PI = East, PI/2 = South, 0 = West
                
                self.delegate?.motionTracker(self, didReceiveHeading: heading, withTimestamp: timestamp)
            }
        }
    }
    
    private func handlePedometerData(data: [[String:String]]) {
        for d in data {
            let distance: Double = NSString(string: d["distance"]!).doubleValue
            
            let startTimeInterval: Double = NSString(string: d["startTime"]!).doubleValue
            let startDate: NSDate = self.pedometerPlayer.convertRelativeDateToAbsolute(startTimeInterval) // relative timestamp to playerstart
            
            let endTimeInterval: Double = NSString(string: d["endTime"]!).doubleValue
            let endDate: NSDate = self.pedometerPlayer.convertRelativeDateToAbsolute(endTimeInterval) // relative timestamp to playerstart
            
            self.delegate?.motionTracker(self, didReceiveDistance: distance, withStartDate: startDate, andEndDate: endDate)
        }
    }
    
    private func handleActivityData(data: [[String:String]]) {
        for d in data {
            let startTimeInterval: Double = NSString(string: d["startDate"]!).doubleValue
            let startDate: NSDate = self.pedometerPlayer.convertRelativeDateToAbsolute(startTimeInterval) // relative timestamp to playerstart
            
            let stationary: Bool = NSString(string: d["stationary"]!).boolValue
            let confidence: Int = NSString(string: d["confidence"]!).integerValue
            
            self.delegate?.motionTracker(self, didReceiveMotionActivityData: stationary, withConfidence: CMMotionActivityConfidence(rawValue: confidence)!, andStartDate: startDate)
        }
    }
}