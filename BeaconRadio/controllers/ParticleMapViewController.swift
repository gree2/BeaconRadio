//
//  MapViewController.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 30/10/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation

class ParticleMapViewController: UIViewController, Observer, UIScrollViewDelegate, ParticleMapViewDataSource {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var particleMapView: ParticleMapView!
    
    
    private lazy var map:Map? = {
        return MapsManager().loadMap(name: "F007")
    }()
    
    private lazy var particleFilter: ParticleFilter? = {
        if let map = self.map {
            return ParticleFilter(map: self.map!)
        } else {
            return nil
        }
    }()
    

    // MARK: UIViewController methods
    override func viewDidLoad() {
        super.viewDidLoad()

        self.scrollView.delegate = self
        self.particleMapView.dataSource = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let particleFilter = self.particleFilter {
            particleFilter.addObserver(self)
            particleFilter.startLocalization()
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        if let particleFilter = self.particleFilter {
            particleFilter.removeObserver(self)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

    
    // MARK: Observer protocol
    func update() {
        println("View needs update")
        self.particleMapView.setNeedsDisplay()
    }

    
    // MARK: ParticleView DataSource
    func mapImgForParticleMapView(view: ParticleMapView) -> UIImage? {
        return self.map?.mapImg
    }
    
    func particlesForParticleMapView(view: ParticleMapView) -> [Particle] {
        if let particleFilter = self.particleFilter {
            return particleFilter.particles
        } else {
            return []
        }
    }
    
    
    // MARK: UIScrollView delegate
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return self.particleMapView
    }

}