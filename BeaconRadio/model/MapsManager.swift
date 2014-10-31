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
            let path = dir.stringByAppendingPathComponent("maps/\(name).png")
            
            let mapImg = UIImage(contentsOfFile: path)
            
            // TODO: Read maps parameter from .plist file
            
            if mapImg != nil {
                return Map(map: mapImg!, scale: 100, orientation: 0)
            }
            
        }
        return nil
    }
    
    
}
