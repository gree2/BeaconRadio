//
//  BeaconViewController.swift
//  IndoorLocalization
//
//  Created by Thomas Bopst on 07/10/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import UIKit


class BeaconViewController: UITableViewController, UITableViewDelegate, UITableViewDataSource, Observer {
    
    private var beacons = BeaconModel.sharedInstance.getBeacons()
    
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "RangingDetails" {
            let detailsViewController = segue.destinationViewController as BeaconDetailsViewController
            
            if let indexPath = tableView.indexPathForSelectedRow() {
                detailsViewController.beaconID = beacons[indexPath.row]
            }
        }
    }
    
    // MARK: UITableViewDelegate protocol
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header = view as UITableViewHeaderFooterView
        header.textLabel.font = UIFont.boldSystemFontOfSize(12.0)
    }
    
    
    // MARK: UITableViewDatasource protocol
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        // load new beacons
        self.beacons = BeaconModel.sharedInstance.getBeacons()
        
        return 1
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        var title: String = ""
        
        if let beaconID = beacons.first {
            title = "UUID: " + beaconID.proximityUUID.UUIDString
        }
        return title
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.beacons.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cellIdentifier = "Cell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as UITableViewCell
        
        if indexPath.row < beacons.count {
            
            
            let major = cell.contentView.viewWithTag(1) as UILabel
            let minor = cell.contentView.viewWithTag(3) as UILabel
            let rssi = cell.contentView.viewWithTag(5) as UILabel
            let accuracy = cell.contentView.viewWithTag(7) as UILabel
            //let proximity = cell.contentView.viewWithTag(9) as UILabel
            
            let beaconID = beacons[indexPath.row]
            
            major.text = "\(beaconID.major)"
            minor.text = "\(beaconID.minor)"
            
            if let logEntry = BeaconModel.sharedInstance.getActualLogEntryForBeacon(beaconID) {
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