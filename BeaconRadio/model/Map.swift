//
//  Map.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 30/10/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation

struct Size {
    let x: Double // m
    let y: Double // m
}


class Map {
    let mapImg: UIImage
    let scale: UInt // 1m = x pixel (1 <= scale <= 100)
    let mapOrientation: Double // degree (0 = North, 90 = East, ...)
    var size: Size {
        get {
            return Size(x: Double(self.mapImg.size.width)/Double(self.scale), y: Double(self.mapImg.size.height)/Double(self.scale))
        }
    }
    let landmarks: [String: Landmark] = [:]
    
    init (map: UIImage, scale: UInt, orientation: Double, landmarks: [Landmark]) {
        self.mapImg = map;
        self.scale = scale;
        self.mapOrientation = orientation
        
        for lm in landmarks {
            self.landmarks.updateValue(lm, forKey: lm.idString)
        }
        
    }
    
    func isCellFree(x: Double, y: Double) -> Bool {
        
        if 0 <= x && x <= self.size.x && 0 <= y && y <= self.size.y {
            let color = self.mapImg.getPixelColor(pos2Pixel(x, y: y))
            let white = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
            return color.isEqual(white) // white
        }
        return false
    }
    
    private func pos2Pixel(x: Double, y: Double) -> CGPoint {
        return CGPoint( x: CGFloat(x * Double(self.scale)), y: CGFloat(y * Double(self.scale)) )
    }
    
}

