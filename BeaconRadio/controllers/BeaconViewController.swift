//
//  BeaconViewController.swift
//  IndoorLocalization
//
//  Created by Thomas Bopst on 07/10/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import UIKit


class BeaconViewController: UITableViewController, UITableViewDelegate, UITableViewDataSource, Observer {
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    
    // MARK: UITableViewDelegate protocol
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header = view as UITableViewHeaderFooterView
        header.textLabel.font = UIFont.boldSystemFontOfSize(12.0)
    }
    
    
    // MARK: UITableViewDatasource protocol
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        var title: String = ""
        
        if let beaconID = BeaconModel.sharedInstance.getBeacons().first {
            title = "UUID: " + beaconID.proximityUUID.UUIDString
        }
        return title
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return BeaconModel.sharedInstance.getBeacons().count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let beaconIDs = BeaconModel.sharedInstance.getBeacons()
        
        let cellIdentifier = "Cell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as UITableViewCell
        
        if indexPath.row < beaconIDs.count {
            
            
            let major = cell.contentView.viewWithTag(1) as UILabel
            let minor = cell.contentView.viewWithTag(3) as UILabel
            let rssi = cell.contentView.viewWithTag(5) as UILabel
            let accuracy = cell.contentView.viewWithTag(7) as UILabel
            //let proximity = cell.contentView.viewWithTag(9) as UILabel
            
            let beaconID = beaconIDs[indexPath.row]
            
            major.text = "\(beaconID.major)"
            minor.text = "\(beaconID.minor)"
            
            if let logEntry = BeaconModel.sharedInstance.getActualLogEntryForBeacon(beaconIDs[indexPath.row]) {
                rssi.text = "\(logEntry.rssi)"
                
                let accuracyValue: Double = Double(Int(logEntry.accuracy*100))/100.0
                accuracy.text = "\(accuracyValue)"
                //proximity.text = logEntry.proximity.description()
            }
            
            
        }
        return cell
    }
    
    
    // MARK: Observer protocol
    
    func update() {
        self.tableView.reloadData()
    }
    
}