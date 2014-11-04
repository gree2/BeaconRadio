//
//  MapViewController.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 30/10/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation

class MapViewController: UIViewController, UIScrollViewDelegate, ParticleMapViewDataSource {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var particleMapView: ParticleMapView!
    
    private var map:Map?
    

    // MARK: UIViewController methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.scrollView.delegate = self
        self.particleMapView.dataSource = self
        
        let mapsManager = MapsManager()
        self.map = mapsManager.loadMap(name: "F007")
        
        if let mapImg = self.map?.mapImg {
            self.particleMapView.showMap(mapImg)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        
        resetMapZoom()
        
        self.particleMapView.update()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
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
    private func resetMapZoom() {
        if let mapImg = self.map?.mapImg {
            
            // zoom
            let widthScale = self.scrollView.bounds.size.width / mapImg.size.width
            let heightScale = self.scrollView.bounds.size.height / mapImg.size.height
            
            let zoomScale = max(widthScale, heightScale)
            
            self.scrollView.setZoomScale(zoomScale, animated: false)
            self.scrollView.minimumZoomScale = zoomScale
//            self.scrollView.maximumZoomScale = 2.0
        }
    }
    
    private func centerMap() {
        let offsetX:CGFloat = max((self.scrollView.bounds.size.width - self.particleMapView.bounds.size.width) / 2, 0.0)
        let offsetY:CGFloat = max((self.scrollView.bounds.size.height - self.particleMapView.bounds.size.height) / 2, 0.0)
        
        self.particleMapView.center = CGPoint(x: self.particleMapView.bounds.size.width / 2 + offsetX, y: self.particleMapView.bounds.size.height / 2 + offsetY);
        
    }
    
    // MARK: ParticleView DataSource
    func particlesForParticleMapView(particleMapView: ParticleMapView) -> [Particle] {
        return [Particle(x: 300, y: 200, orientation: 0), Particle(x: 300, y: 300, orientation: 90), Particle(x: 300, y: 400, orientation: 180), Particle(x: 300, y: 500, orientation: 270),Particle(x: 500, y: 200, orientation: 45), Particle(x: 500, y: 300, orientation: 135), Particle(x: 500, y: 400, orientation: 225), Particle(x: 500, y: 500, orientation: 315)] //
    }

}