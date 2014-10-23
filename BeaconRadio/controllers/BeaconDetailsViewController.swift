//
//  BeaconDetailsViewController.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 09/10/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

class BeaconDetailsViewController: UIViewController, Observer {
    
    @IBOutlet weak var uuidLabel: UILabel!
    @IBOutlet weak var majorLabel: UILabel!
    @IBOutlet weak var minorLabel: UILabel!
    @IBOutlet weak var proximityLabel: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!
    @IBOutlet weak var accuracyLabel: UILabel!
    @IBOutlet weak var log2FileItemsLabel: UILabel!
    @IBOutlet weak var log2FileBtn: UIButton!
    
    var beacon: CLBeacon?
    private var beaconID: BeaconID?
    
    private let log2fileLogManger = BeaconLogManager()
    private var isLogging = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.log2FileBtn.setTitle("start", forState: UIControlState.Normal)
        self.log2FileBtn.setTitle("stop", forState: UIControlState.Selected)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let b = self.beacon {
            
            self.beaconID = BeaconID(proximityUUID: b.proximityUUID, major: b.major.integerValue, minor: b.minor.integerValue)
            
            uuidLabel.text = b.proximityUUID.UUIDString
            majorLabel.text = "\(b.major)"
            minorLabel.text = "\(b.minor)"
        }
        
        update()
        
        // register observer
        BeaconRadar.sharedInstance.addObserver(self)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        // unregister observer
        BeaconRadar.sharedInstance.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "BeaconRangingChart" {
            let chartViewController = segue.destinationViewController as BeaconRangingChartViewController
            chartViewController.beacon = self.beacon
        }
    }
    
    // MARK: Observer protocol
    func update() {

        self.beacon = BeaconRadar.sharedInstance.getBeacon(self.beaconID!)

        if self.beacon != nil && self.beacon?.proximity != CLProximity.Unknown {
            rssiLabel.text = "\(self.beacon!.rssi) db"
            accuracyLabel.text = "\(Double(Int(self.beacon!.accuracy*100))/100.0) m"
            proximityLabel.text = self.beacon!.proximity.description()
        } else {
            rssiLabel.text = ""
            accuracyLabel.text = ""
            proximityLabel.text = "Unknown"
        }


        if self.beacon != nil && self.isLogging && self.beacon?.proximity != CLProximity.Unknown {
            self.log2fileLogManger.addLogEntry(self.beacon!)
            self.log2FileItemsLabel.text = "Items: \(self.log2fileLogManger.countLogEntriesForBeacon(self.beaconID!)!)"
        }

    }
    
    @IBAction func log2FileBtnPressed(sender: UIButton) {
        
        if (self.isLogging) {
            // stop
            
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss_"
            
            let filename = "\(dateFormatter.stringFromDate(NSDate()))\(self.beaconID!.description()).csv"
            
            self.log2fileLogManger.save2File(filename)
            self.log2fileLogManger.clearLog()
        }
        
        self.isLogging = !self.isLogging
        sender.selected = self.isLogging
    }
}