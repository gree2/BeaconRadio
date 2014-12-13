//
//  DataPlayer.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 21/11/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation

class DataPlayer {
    
    var attributes: [String] = []
    let timestampKey = "timestamp"
    private var data = [[String: String]]()
    private var delegate: DataPlayerDelegate? = nil
    var startDate: NSDate?
    
    init() {
        
    }
    
    func load(dataStoragePath path: String, error: NSErrorPointer) {
        
        let deliminator = ","
        
        if let content = String(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: error) {
            
            var lines = [String]()
            
            content.stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet()).enumerateLines({line, stop in lines.append(line)})
            
            for line in lines {
                
                if line == lines.first {
                    self.attributes += line.componentsSeparatedByString(deliminator)
                } else {
                    
                    var dataRecord = [String:String]()
                    
                    let values = line.componentsSeparatedByString(deliminator)
                    
                    for (index, attribute) in enumerate(self.attributes) {
                        dataRecord[attribute] = values[index]
                    }
                    
                    self.data.append(dataRecord)
                }
            }
        }
    }
    
    func playback(delegate: DataPlayerDelegate) {
        
        self.delegate = delegate
        
        self.startDate = NSDate()
        
        var precedingTime: Double = -1
        var records: [[String: String]] = []
        
        for record in self.data {
            
            let time = NSString(string: record[self.timestampKey]!).doubleValue
            
            if precedingTime != -1 && time > precedingTime {
                let timer = NSTimer(timeInterval: precedingTime, target: self, selector: Selector("timerFired:"), userInfo: records, repeats: false)
                NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
                records = []
            }
            
            records.append(record)
            
            if record == self.data.last! {
                let timer = NSTimer(timeInterval: time, target: self, selector: Selector("timerFired:"), userInfo: records, repeats: false)
                NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
            }
            
            precedingTime = time
        }
    }
    
    @objc func timerFired(timer: NSTimer) {
        
        if let del = self.delegate {
            del.dataPlayer(self, handleData: timer.userInfo as [[String:String]])
        }
    }
    
    func convertRelativeDateToAbsolute(relative: NSTimeInterval) -> NSDate {
        if relative <= 0.0 {
            return self.startDate!
        } else {
            return self.startDate!.dateByAddingTimeInterval(relative)
        }
    }
    
}

protocol DataPlayerDelegate {
    func dataPlayer(player: DataPlayer, handleData data: [[String:String]])
}