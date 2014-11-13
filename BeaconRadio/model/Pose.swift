//
//  Pose.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 12/11/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation


struct Pose {
    
    let x: Double // m
    let y: Double // m
    let theta: Double // radian [0, 2*M_PI)
    
    init(x: Double, y: Double, theta: Double) {
        self.x = x
        self.y = y
        
        // make sure that theta is [0, 2*M_PI)
        var theta_tmp = theta % (2 * M_PI)
        if theta_tmp < 0 {
           theta_tmp += 2 * M_PI
        }
        self.theta = theta_tmp
    }
    
    func description() -> String {
        return "Pose with x: \(self.x)m, y: \(self.y)m, theta: \(self.theta)rad (\(Angle.unitCircleRad2CompassDeg(self.theta)) compassDeg)"
    }
}