//
//  NormalDistribution.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 14/11/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation

class NormalDistribution {
    class func pdf(x: Double, mu: Double, sigma: Double) -> Double {
        return ( 1 / (sqrt(2 * M_PI) * sigma) ) * exp(-0.5 * pow((x-mu), 2) / (sigma * sigma))
    }
}