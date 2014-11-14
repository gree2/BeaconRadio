//
//  MapManager.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 30/10/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation
import CoreLocation

class MapsManager {
    
    let dirPath: String?
    
    init() {
        let dirs: [String]? = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true) as? [String]
        
        if let directories = dirs {
            let dir = directories[0];
            self.dirPath = dir.stringByAppendingPathComponent("maps")
        }
    }
    
    
    func mapNames() -> [String] {
        
        var maps: [String] = []
        
        if let path = self.dirPath {
            if let content = NSFileManager.defaultManager().contentsOfDirectoryAtPath(path, error: nil) {
                for c in content {
                    if c is NSString {
                        maps.append(c as String)
                        println("Content in dir: \(c)")
                    }
                }
            }
            
            return maps;
        }
        return []
    }
    
    func loadMap(#name: String) -> Map? {
        
        let dirs: [String]? = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true) as? [String]
        
        if let directories = dirs {
            let dir = directories[0];
            let mapPath = dir.stringByAppendingPathComponent("maps/\(name).png")
            var error: Bool = false
            
            if let mapImg = UIImage(contentsOfFile: mapPath) {
                
                let plistPath = dir.stringByAppendingPathComponent("maps/\(name).plist")
                
                if let plist = NSDictionary(contentsOfFile: plistPath) {
                    
                    let scale = plist.valueForKey("scale") as UInt
                    let orientation = plist.valueForKey("orientation") as Double
                    let lms = plist.valueForKey("landmarks") as [NSDictionary]
                    
                    if scale < 1 || scale > 100 {
                        error = true
                        println("[ERROR] Couldn't load plist file that corresponds to map named '\(name)'. Reason: Scale must be 1 < scale <= 100.")
                    }
                    if orientation < 0 || orientation >= 360 {
                        error = true
                        println("[ERROR] Couldn't load plist file that corresponds to map named '\(name)'. Reason: Orientation must be 0 <= orientation < 360.")
                    }
                    
                    var landmarks: [Landmark] = []
                    
                    for lm in lms {
                        let proximityUUID = NSUUID(UUIDString: lm.valueForKey("proximityUUID") as String)
                        let major = lm.valueForKey("major") as UInt
                        let minor = lm.valueForKey("minor") as UInt
                        let x = lm.valueForKey("x") as Double
                        let y = lm.valueForKey("y") as Double
                        
                        if x < 0 || y < 0 {
                            error = true
                            println("[ERROR] Couldn't load plist file that corresponds to map named '\(name)'. Reason: Landmark x and/or y must be > 0.")
                        } else {
                            landmarks.append(Landmark(uuid: proximityUUID!, major: major, minor: minor, x: x, y: y))
                        }
                    }
                        
                    if !error {
                        return Map(map: mapImg, scale: scale, orientation: orientation, landmarks: landmarks)
                    }
                    
                } else {
                    println("[ERROR] Couldn't load plist file that corresponds to map named '\(name)'.")
                }
                
            } else {
                println("[ERROR] Couldn't load map named '\(name)'.")
            }
        }
        return nil
    }
    
    
}
