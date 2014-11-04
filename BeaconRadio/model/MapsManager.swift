//
//  MapManager.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 30/10/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation

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
            
            if let mapImg = UIImage(contentsOfFile: mapPath) {
                
                let plistPath = dir.stringByAppendingPathComponent("maps/\(name).plist")
                
                if let plist = NSDictionary(contentsOfFile: plistPath) {
                    
                    let scale = plist.valueForKey("scale") as Double
                    let orientation = plist.valueForKey("orientation") as Double
                    
                    if scale <= 0 {
                        println("[ERROR] Couldn't load plist file that corresponds to map named '\(name)'. Reason: Scale must be > 0.")
                    }else if orientation < 0 || orientation >= 360 {
                        println("[ERROR] Couldn't load plist file that corresponds to map named '\(name)'. Reason: Orientation must be 0 <= orientation < 360.")
                    } else {
                        return Map(map: mapImg, scale: scale, orientation: orientation)
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
