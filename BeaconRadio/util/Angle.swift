//
//  Angle.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 12/11/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation

class Angle {
    
    // relative conversion (e.g. 90deg = PI/2)
    class func deg2Rad(deg: Double) -> Double {
        return (deg * M_PI / 180.0) % (2 * M_PI)
    }
    
    // relative conversion (e.g. PI/2 = 90deg)
    class func rad2Deg(rad: Double) -> Double {
        return (rad * 180.0 / M_PI) % 360
    }
    

    /**
     * compass degree -> unit circle radian
     * 0deg = North = PI/2 rad, 90deg = East = 0,
     * 180deg = South = 3/2*PI rad, 270deg = West = PI
    **/
    class func compassDeg2UnitCircleRad(deg: Double) -> Double {
        
        let degInRad = deg2Rad(deg)
        
        var rad = (M_PI_2 - degInRad) % (2 * M_PI)
        
        if rad < 0 {
            rad += (2 * M_PI)
        }
        
        return rad
    }
    
    /**
    * unit circle radian -> compass degree
    * 0deg = North = PI/2 rad, 90deg = East = 0,
    * 180deg = South = 3/2*PI rad, 270deg = West = PI
    **/
    class func unitCircleRad2CompassDeg(rad: Double) -> Double {
        
        let radInDeg = rad2Deg(rad)
        
        var deg = (90 - radInDeg) % 360.0
        
        if deg < 0 {
            deg += 360.0
        }
        
        return deg
    }
}