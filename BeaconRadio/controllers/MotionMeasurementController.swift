//
//  MotionMeasurementController.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 23/10/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation
import CoreMotion


class MotionMeasurementController: UIViewController {
    @IBOutlet weak var distance: UILabel!
    @IBOutlet weak var speed: UILabel!
    @IBOutlet weak var steps: UILabel!

    @IBOutlet weak var startstopBtn: UIButton!
    let pedometer = CMPedometer()
    
    var startTime: NSDate?
    var stopTime: NSDate?
    
    let lengthFormatter = NSLengthFormatter()
    let timeFormatter = NSDateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.timeFormatter.dateFormat = "HH:mm:ss"
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        
        println("Is step counting available: \(CMPedometer.isStepCountingAvailable())")
        println("Is distance available: \(CMPedometer.isDistanceAvailable())")
        println("Is floor counting available: \(CMPedometer.isFloorCountingAvailable())")
        
        self.startstopBtn.setTitle("start", forState: UIControlState.Normal)
        self.startstopBtn.setTitle("stop", forState: UIControlState.Selected)
        
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func query(sender: AnyObject) {

        if startTime == nil {
            self.startTime = NSDate()
            self.stopTime = nil
            
            self.steps.text = "Steps Taken: "
            self.distance.text = "Distance: "
            self.speed.text = "Duration: "
            
/*            self.pedometer.startPedometerUpdatesFromDate(self.startTime!, withHandler: { data, error in
                if !(error != nil) {
                    println("Steps Taken: \(data.numberOfSteps)")
                    self.steps.text = "Steps Taken: \(data.numberOfSteps)"
                    
                    var distance = data.distance.doubleValue
                    println("Distance: \(self.lengthFormatter.stringFromMeters(distance))")
                    self.distance.text = "Distance: \(self.lengthFormatter.stringFromMeters(distance))"
                    
                    var time = data.endDate.timeIntervalSinceDate(data.startDate)
                    var speed = distance / time
                    println("Speed: \(self.lengthFormatter.stringFromMeters(speed)) / s")
                    self.speed.text = "Speed: \(self.lengthFormatter.stringFromMeters(speed)) / s"
                }
            })*/
            self.startstopBtn.selected = true
        } else {
//            self.pedometer.stopPedometerUpdates()
            self.stopTime = NSDate()
            self.pedometer.queryPedometerDataFromDate(self.startTime, toDate: self.stopTime, withHandler: { data, error in
                if !(error != nil) {
                    
                    self.steps.text = "Steps Taken: \(data.numberOfSteps)"
                    
                    var distance = data.distance.doubleValue
                    
                    self.distance.text = "Distance: \(self.lengthFormatter.stringFromMeters(distance))"
                    
                    var time = data.endDate.timeIntervalSinceDate(data.startDate)
                    
                    var speed = 20.0 / time
                    self.speed.text = "Speed: \(self.lengthFormatter.stringFromMeters(speed)) / s"
                }
            })
            
            self.startTime = nil
            self.startstopBtn.selected = false
        }
        
    }
    
}