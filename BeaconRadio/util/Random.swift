//
//  Random.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 11/11/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation

class Random {
    
    /*
    * @see: Probabilistic Robots, S. Thrun et al, Page 124
    */
    class func sample_normal_distribution(sigma:Double) -> Double {
        
        var sum = 0.0
        
        for var i = 0; i < 12; ++i {
            sum += rand_uniform(sigma)
        }
        return sum * 0.5
    }
    
//    // Returns a tupel with two independent standard normal distributed random variables
//    class func rand_normal() -> (Double, Double) {
//        
//        /* 
//         * Uses Box-Müller to transform uniform distributed random variable to normal/gaussian random distributed value
//         * https://developer.apple.com/library/mac/documentation/Darwin/Reference/Manpages/man3/arc4random_uniform.3.html
//         */
//        
//        var x1, x2, w, y1, y2: Double
//        
//        do {
//            x1 = 2.0 * rand_uniform() - 1.0
//            x2 = 2.0 * rand_uniform() - 1.0
//            w = x1 * x1 + x2 * x2
//        } while w >= 1.0
//        
//        w = sqrt( (-2.0 * log( w ) ) / w ) // log = natural logarithm https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man3/math.3.html
//        y1 = x1 * w
//        y2 = x2 * w
//        
//        return (y1, y2)
//    }
    

    class func rand_uniform(sigma: Double) -> Double {
        let decimalDigits: Int = 4
        let decimalFactor = UInt32(pow(10.0, Double(decimalDigits))*2*sigma)
        
        return Double(arc4random_uniform(decimalFactor))/Double(decimalFactor) - sigma
    }
}