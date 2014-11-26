//
//  Util.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 24/11/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation

class Util {
    
    class func pathToLogfiles() -> String? {
        let dirs : [String]? = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true) as? [String]
        return dirs?.first
    }
    
    class func pathToLogfileWithName(name: String) -> String? {
        return Util.pathToLogfiles()?.stringByAppendingPathComponent(name)
    }
}