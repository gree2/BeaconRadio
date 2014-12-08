//
//  Logger.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 18/11/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation

class Logger {
    // MARK: Singleton
    class var sharedInstance: Logger {
        struct Static {
            static var instance: Logger?
            static var token: dispatch_once_t = 0
        }
        dispatch_once(&Static.token) {
            Static.instance = Logger()
        }
        return Static.instance!
    }
    
    private lazy var dateFormatter: NSDateFormatter = {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd_HH-mm-ss"
        return dateFormatter
    }()
    
    private lazy var logBuffer:[String] = {
        var a:[String] = []
        a.reserveCapacity(50)
        return a
    }()
    
    private lazy var operationQueue: NSOperationQueue = {
        var q = NSOperationQueue()
        q.qualityOfService = .Background
        return q
    }()
    
    func log(message m: String) {
        
        let timestamp = self.dateFormatter.stringFromDate(NSDate())
        let logEntry = "[\(timestamp)] \(m)\n"
        
        self.logBuffer.append(logEntry)
        
        if self.logBuffer.count >= self.logBuffer.capacity {
            save2File()
        }
    }
    
    func save2File() {
        
        self.operationQueue.addOperationWithBlock({
            let dirs : [String]? = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true) as? [String]
            
            if let directories = dirs {
                let dir = directories[0]; //documents directory
                let path = dir.stringByAppendingPathComponent("\(self.dateFormatter.stringFromDate(NSDate()))_Log.txt");
                
                let content:String = self.logBuffer.reduce("", combine: +)
                self.logBuffer.removeAll(keepCapacity: true)
                
                //writing
                content.writeToFile(path, atomically: false, encoding: NSUTF8StringEncoding, error: nil);
            }
        })
    }
}