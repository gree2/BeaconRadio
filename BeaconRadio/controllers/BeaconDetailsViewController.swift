//
//  BeaconDetailsViewController.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 09/10/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation
import UIKit

class BeaconDetailsViewController: UIViewController, Observer {
    
    @IBOutlet weak var uuidLabel: UILabel!
    @IBOutlet weak var majorLabel: UILabel!
    @IBOutlet weak var minorLabel: UILabel!
    @IBOutlet weak var proximityLabel: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!
    @IBOutlet weak var accuracyLabel: UILabel!
    
    var beaconID: BeaconID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        update()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        // register observer
        BeaconModel.sharedInstance.addObserver(self)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        // unregister observer
        BeaconModel.sharedInstance.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "BeaconRangingChart" {
            let chartViewController = segue.destinationViewController as BeaconRangingChartViewController
            chartViewController.beaconID = self.beaconID
        }
    }
    
    // MARK: Observer protocol
    func update() {

        
        if let bID = self.beaconID {
            uuidLabel.text = bID.proximityUUID.UUIDString
            majorLabel.text = "\(bID.major)"
            minorLabel.text = "\(bID.minor)"
            
            if let log = BeaconModel.sharedInstance.getActualLogEntryForBeacon(bID) {
                rssiLabel.text = "\(log.rssi) db"
                accuracyLabel.text = "\(Double(Int(log.accuracy*100))/100.0) m"
                proximityLabel.text = log.proximity.description()
            }
        }
        
    }
}