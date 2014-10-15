//
//  BeaconRangingChartViewController.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 10/10/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

class BeaconRangingChartViewController: UIViewController, Observer {
    
    var beacon: CLBeacon?
    private var beaconID: BeaconID?
    
    private let beaconLog = BeaconLogManager(capacity: 30)
    
    private var rssiChart: NCISimpleChartView?
    private var accuracyChart: NCISimpleChartView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        // register observer
        
        if let b = self.beacon {
            self.beaconID = BeaconID(proximityUUID: b.proximityUUID, major: b.major, minor: b.minor)
        }
        
        setup()
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
    
    private func setup() {
        
        let rssiChartOptions = [
            nciIsSmooth: [false],
            nciIsFill: [false],
            nciHasSelection: false,
            nciGridTopMargin: 20,
            nciGridBottomMargin: 20,
            nciGridLeftMargin: 50,
            nciGridRightMargin: 50,
            nciLineWidths:[1],
            nciLineColors: [UIColor.blueColor()],
            nciYAxis: [
                nciAxisShift: 0,
                nciInvertedLabes: false,
                nciLineWidth: 2,
                nciLineDashes: [],
                nciLineColor: UIColor.blueColor(),
                nciLabelsColor: UIColor.blueColor()
            ],
            nciXAxis: [
                nciLineWidth: 2,
                nciAxisShift : self.view.frame.size.height-40,
                nciInvertedLabes: false,
                nciLineDashes: []
        ]]
        
        let accuracyChartOptions = [
            nciIsSmooth: [false],
            nciIsFill: [false],
            nciHasSelection: false,
            nciGridTopMargin: 20,
            nciGridBottomMargin: 20,
            nciGridLeftMargin: 50,
            nciGridRightMargin: 50,
            nciLineWidths:[1],
            nciLineColors: [UIColor.redColor()],
            nciYAxis: [
                nciAxisShift: self.view.frame.size.width-100,
                nciInvertedLabes: true,
                nciLineWidth: 2,
                nciLineDashes: [],
                nciLineColor: UIColor.redColor(),
                nciLabelsColor: UIColor.redColor()
            ],
            nciXAxis: [
                nciLineWidth: 2,
                nciAxisShift : self.view.frame.size.height-40,
                nciInvertedLabes: false,
                nciLineDashes: [] // required (bug in chart view, otherwise the chart's line will be dashed)
        ]]
        
        if self.rssiChart == nil {
            self.rssiChart = NCISimpleChartView(frame: CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height), andOptions: rssiChartOptions)
            self.view.addSubview(self.rssiChart!)
        }
        
        if self.accuracyChart == nil {
            self.accuracyChart = NCISimpleChartView(frame: CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height), andOptions: accuracyChartOptions)
            self.view.addSubview(self.accuracyChart!)
        }
        
        update()
    }
    
    // MARK: Observer protocol
    func update() {

        if let beacon = self.beacon {

            self.beacon = BeaconRadar.sharedInstance.getBeacon(self.beaconID!)
            
            if self.beacon != nil && self.beacon?.proximity != CLProximity.Unknown {
                self.beaconLog.addLogEntry(self.beacon!)
            }
            
            rssiChart?.chartData.removeAllObjects()
            accuracyChart?.chartData.removeAllObjects()
            
            var i = 0
            for logEntry in self.beaconLog.getLogEntriesForBeacon(self.beaconID!) {
                rssiChart?.addPoint(Double(i), val: [Double(logEntry.rssi!)])
                accuracyChart?.addPoint(Double(i), val: [logEntry.accuracy!])
                ++i
            }
            
            rssiChart?.drawChart()
            accuracyChart?.drawChart()
        }
    }
}