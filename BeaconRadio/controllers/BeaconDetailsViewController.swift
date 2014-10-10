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
    
    
    // MARK: Observer protocol
    func update() {
        let uuid = view.viewWithTag(1) as UILabel
        let major = view.viewWithTag(3) as UILabel
        let minor = view.viewWithTag(5) as UILabel
        let rssi = view.viewWithTag(7) as UILabel
        let accuracy = view.viewWithTag(9) as UILabel
        let proximity = view.viewWithTag(11) as UILabel
        
        if let bID = self.beaconID {
            uuid.text = bID.proximityUUID.UUIDString
            major.text = "\(bID.major)"
            minor.text = "\(bID.minor)"
            
            if let log = BeaconModel.sharedInstance.getActualLogEntryForBeacon(bID) {
                rssi.text = "\(log.rssi)"
                accuracy.text = "\(Double(Int(log.accuracy*100))/100.0)"
                proximity.text = log.proximity.description()
            }
        }
        
    }
}