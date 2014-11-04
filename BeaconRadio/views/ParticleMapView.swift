//
//  MapView.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 31/10/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation
import UIKit

class ParticleMapView: UIView, ParticleViewDataSource {
    @IBOutlet weak var mapView: UIImageView!
    @IBOutlet weak var particleView: ParticleView!

    
    var mapSize: CGSize {
        get {
            return self.mapView.bounds.size
        }
    }
    
    var dataSource: ParticleMapViewDataSource?
    
    required init(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        NSBundle.mainBundle().loadNibNamed("ParticleMapView", owner: self, options: nil)
        self.addSubview(self.mapView)
        self.particleView.dataSource = self
    }
    
    func showMap(mapImg: UIImage) {
        self.mapView.image = mapImg
    }
    
    func update() {
        self.particleView.setNeedsDisplay()
    }
    

    // MARK: ParticleViewDataSource
    func particlesForParticleView(particleView:ParticleView) -> [Particle] {
        if let dataSource = self.dataSource {
            return dataSource.particlesForParticleMapView(self)
        }
        return []
    }
    
}

protocol ParticleMapViewDataSource {
    func particlesForParticleMapView(particleMapView:ParticleMapView) -> [Particle]
    //func mapForParticleMapView(particleMapView: ParticleMapView) -> UIImage
}