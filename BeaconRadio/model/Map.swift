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
    private let pixelData: CFData
    
    init (map: UIImage, scale: UInt, orientation: Double, landmarks: [Landmark]) {
        self.mapImg = map;
        self.scale = scale;
        self.mapOrientation = orientation
        
        for lm in landmarks {
            self.landmarks.updateValue(lm, forKey: lm.idString)
        }
        
        self.pixelData = CGDataProviderCopyData(CGImageGetDataProvider(self.mapImg.CGImage))
        
    }
    
    func isCellFree(#x: Double, y: Double) -> Bool {
        
        if 0.0 <= x && x < self.size.x && 0.0 <= y && y < self.size.y {
            let pixel = pos2Pixel(x: x, y: y)
            
            if 0 <= pixel.x && pixel.x < Int(self.mapImg.size.width) && 0 <= pixel.y && pixel.y < Int(self.mapImg.size.height) {
                
                let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
                
                let pixelInfo: Int = ((Int(self.mapImg.size.width) * Int(pixel.y)) + Int(pixel.x)) * 4
                
                let r = CGFloat(data[pixelInfo])
                let g = CGFloat(data[pixelInfo+1])
                let b = CGFloat(data[pixelInfo+2])
                //            let a = CGFloat(data[pixelInfo+3])
                
                return (r == 255.0 && g == 255.0 && b == 255.0)
            }
        }
        
        return false
    }
    
    private func pos2Pixel(#x: Double, y: Double) -> (x: Int, y: Int) {
        return ( x: Int(x * Double(self.scale)), y: Int(y * Double(self.scale)) )
    }
    
}

