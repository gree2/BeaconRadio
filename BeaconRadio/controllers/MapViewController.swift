//
//  MapViewController.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 30/10/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation

class MapViewController: UIViewController, UIScrollViewDelegate, ParticleMapViewDataSource, Observer {
    
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
        
        if let mapImg = self.map?.mapImg {
            self.particleMapView.showMap(mapImg)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let particleFilter = self.particleFilter {
            particleFilter.addObserver(self)
        }

        
        resetMapZoom()
        
        //self.particleMapView.update()
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
    
    // MARK: UIScrollView delegate
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return self.particleMapView
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
//        resetMapZoom()
        //centerMap()
    }

    // MARK: Helper methods
    
    // FIXME: resetMapZoom
    private func resetMapZoom() {
        if let mapImg = self.map?.mapImg {
            
            // zoom
            let widthScale = self.scrollView.bounds.size.width / mapImg.size.width
            let heightScale = self.scrollView.bounds.size.height / mapImg.size.height
            
            let zoomScale = max(widthScale, heightScale)
            
            self.scrollView.setZoomScale(zoomScale, animated: false)
            self.scrollView.minimumZoomScale = zoomScale
            // self.scrollView.maximumZoomScale = 2.0
        }
    }
    
    // FIXME: centerMap
    private func centerMap() {
        let offsetX:CGFloat = max((self.scrollView.bounds.size.width - self.particleMapView.bounds.size.width) / 2, 0.0)
        let offsetY:CGFloat = max((self.scrollView.bounds.size.height - self.particleMapView.bounds.size.height) / 2, 0.0)
        
        self.particleMapView.center = CGPoint(x: self.particleMapView.bounds.size.width / 2 + offsetX, y: self.particleMapView.bounds.size.height / 2 + offsetY);
        
    }
    
    // MARK: ParticleView DataSource
    func particlesForParticleMapView(particleMapView: ParticleMapView) -> [Particle] {

        var viewParticles: [Particle] = []
        
        if let particleFilter = self.particleFilter {
            let particles = particleFilter.particles
            let map = particleFilter.map
            
            viewParticles.reserveCapacity(particles.count)
            
            let scaleX = self.particleMapView.mapSize.width/map.mapImg.size.width
            let scaleY = self.particleMapView.mapSize.height/map.mapImg.size.height
            
            let scale = min(scaleX, scaleY)
            println("scaleX: \(scaleX), scaleY: \(scaleY)")
            
            // do coordinate conversion
            
            for particle in particles {
                let mapPixel = map.pos2Pixel(Position(x: particle.x, y: particle.y))
                
                let newParticle = Particle(x: UInt(mapPixel.x*scale), y: UInt(mapPixel.y*scale), orientation: particle.orientation)
                
                viewParticles.append(newParticle)
            }
            
        }
        
        return viewParticles
    }

    // MARK: Observer protocol
    func update() {
        self.particleMapView.update()
    }
    
    
}