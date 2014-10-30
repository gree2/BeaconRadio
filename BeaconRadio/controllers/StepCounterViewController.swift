//
//  StepCounterViewController.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 29/10/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation
import CoreMotion

class StepCounterViewController: UIViewController {
    @IBOutlet weak var steps: UILabel!
    @IBOutlet weak var duration: UILabel!
    @IBOutlet weak var startStopBtn: UIButton!
    
    let stepCounter = CMStepCounter()
    
    var startTimestamp = NSDate()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        
        println("Is step counting available: \(CMStepCounter.isStepCountingAvailable())")
        
        self.startStopBtn.setTitle("start", forState: UIControlState.Normal)
        self.startStopBtn.setTitle("stop", forState: UIControlState.Selected)
        
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    @IBAction func toggleStartStopBtn(sender: AnyObject) {
        if CMStepCounter.isStepCountingAvailable() {
            if !self.startStopBtn.selected {
                
                self.startTimestamp = NSDate()
                
                self.stepCounter.startStepCountingUpdatesToQueue(NSOperationQueue.mainQueue(), updateOn: 1, withHandler: {numberOfSteps, timestamp, error in
                    if error == nil {
                        self.steps.text = "Steps: \(numberOfSteps)"
                        self.duration.text = "Duration: \(timestamp.timeIntervalSinceDate(self.startTimestamp)) sec"
                    } else {
                        println("Step Counter error: \(error)")
                    }
                })
                
                self.startStopBtn.selected = true
            } else {
                self.stepCounter.stopStepCountingUpdates()
                self.startStopBtn.selected = false
            }
        }
        
    }
}