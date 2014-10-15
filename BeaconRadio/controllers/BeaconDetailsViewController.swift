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
    
    var beacon: CLBeacon?
    private var beaconID: BeaconID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let b = self.beacon {
            
            self.beaconID = BeaconID(proximityUUID: b.proximityUUID, major: b.major, minor: b.minor)
            
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

        if let b = self.beacon {
            rssiLabel.text = "\(b.rssi) db"
            accuracyLabel.text = "\(Double(Int(b.accuracy*100))/100.0) m"
            proximityLabel.text = b.proximity.description()
        } else {
            rssiLabel.text = ""
            accuracyLabel.text = ""
            proximityLabel.text = "Unknown"
        }
    }
}