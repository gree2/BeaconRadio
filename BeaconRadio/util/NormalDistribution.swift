//
//  NormalDistribution.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 14/11/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation

class NormalDistribution {
    class func pdf(x: Double, mu: Double, sigma_2: Double) -> Double {
        return ( 1 / sqrt(2 * M_PI * sigma_2) ) * exp(-0.5 * pow((x-mu), 2) / sigma_2)
    }
}