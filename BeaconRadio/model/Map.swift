//
//  Map.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 30/10/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation

struct Size {
    let x: UInt // cm
    let y: UInt // cm
}

struct Position {
    let x: UInt // cm
    let y: UInt // cm
}


class Map {
    let mapImg: UIImage
    let scale: UInt // 1m = x pixel (1 <= scale <= 100)
    let mapOrientation: Double // degree (0 = North, 90 = East, ...)
    let sizeInCm: Size
    
    private let gridSize = 10 // in cm
    
    init (map: UIImage, scale: UInt, orientation: Double) {
        self.mapImg = map;
        self.scale = scale;
        self.mapOrientation = orientation
        
        self.sizeInCm = Size(x: UInt(self.mapImg.size.width)/self.scale*100, y: UInt(self.mapImg.size.height)/self.scale*100)
    }
    
    func isCellFree(pos: Position) -> Bool {
        let color = self.mapImg.getPixelColor(pos2Pixel(pos))
        let white = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        return color.isEqual(white) // white
    }
    
    func pos2Pixel(pos: Position) -> CGPoint {
        let x = pos.x/(self.scale/100)
        let y = pos.y/(self.scale/100)
        return CGPoint(x: CGFloat(x), y: CGFloat(y))
    }
    
}

