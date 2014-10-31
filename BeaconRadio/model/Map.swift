//
//  Map.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 30/10/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation

struct Size {
    let width: Double
    let height: Double
}

struct Point {
    let x: Double
    let y: Double
}


class Map {
    let mapImg: UIImage
    let scale: Double // 1m = x pixel
    let mapOrientation: Double // degree (0 = North, 90 = East, ...)
    let sizeInMeters: Size
    
    private let gridSize = 10 // in cm
    
    init (map: UIImage, scale: Double, orientation: Double) {
        self.mapImg = map;
        self.scale = scale;
        self.mapOrientation = orientation
        
        self.sizeInMeters = Size(width: Double(self.mapImg.size.width)/self.scale, height: Double(self.mapImg.size.height)/self.scale)
    }
    
    func isCellFree(pos: Point) -> Bool {
        let color = self.mapImg.getPixelColor(CGPoint(x: pos.x, y: pos.y))
        let white = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        return color.isEqual(white) // white
    }
    
}

