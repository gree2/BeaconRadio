//
//  MotionTrackerSimulator.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 24/11/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation


class MotionTrackerSimulator: IMotionTracker, DataPlayerDelegate {

    private var delegate: MotionTrackerDelegate?
    
    private let headingPlayer = DataPlayer()
    private let pedometerPlayer = DataPlayer()
    // further players currently not beeing used
    
    required init() {
        
    }
    
    func startMotionTracking(delegate: MotionTrackerDelegate) {
        self.delegate = delegate
        
        self.headingPlayer.load(dataStoragePath: Util.pathToLogfileWithName("2014-12-03_16-23_Heading.csv")!, error: nil)
        self.pedometerPlayer.load(dataStoragePath: Util.pathToLogfileWithName("2014-12-03_16-23_Pedometer.csv")!, error: nil)
        
        self.headingPlayer.playback(self)
        self.pedometerPlayer.playback(self)
    }
    
    func stopMotionTracking() {
        
    }
    
    
    // MARK: DataPlayerDelegate protocol
    func dataPlayer(player: DataPlayer, handleData data: [[String:String]]) {
        
        if player === self.headingPlayer {
            handleHeadingData(data)
        } else if player === self.pedometerPlayer {
            handlePedometerData(data)
        }
    }
    
    private func handleHeadingData(data: [[String:String]]) {
        
        for d in data {
            let heading: Double = NSString(string: d["magneticHeading"]!).doubleValue
            
            let timeInterval: Double = NSString(string: d["ts"]!).doubleValue
            let timestamp: NSDate = self.headingPlayer.convertRelativeDateToAbsolute(timeInterval) // relative timestamp to playerstart
            
            self.delegate?.motionTracker(self, didReceiveHeading: heading, withTimestamp: timestamp)
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
}