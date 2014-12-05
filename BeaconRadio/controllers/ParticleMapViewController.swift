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
    
    @IBOutlet weak var startStopLocalization: UIBarButtonItem!
    
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
    
    @IBAction func toggleLocalization(sender: UIBarButtonItem) {
        
        if let particleFilter = self.particleFilter {
            
            if particleFilter.isRunning {
                particleFilter.removeObserver(self)
                particleFilter.stopLocalization()
                self.startStopLocalization.title = "Start"
            } else {
                particleFilter.addObserver(self)
                particleFilter.startLocalization()
                self.startStopLocalization.title = "Stop"
            }
        }
    }

    // MARK: Observer protocol
    func update() {
        self.particleMapView.setNeedsDisplay()
    }

    
    // MARK: ParticleView DataSource
    func mapImgForParticleMapView(view: ParticleMapView) -> UIImage? {
        return self.map?.mapImg
    }
    
    func particlesForParticleMapView(view: ParticleMapView) -> [Particle] {

        if let map = self.map {
            if let particleFilter = self.particleFilter {
                
                let particles = particleFilter.particles
                
                // convert particles to right size
                return particles.map({p in self.transformParticle(p, ToMapCS: map)})
            }
        }
        return []
    }
    
    func estimatedPathForParticleMapView(view: ParticleMapView) -> [Pose] {
        if let map = self.map {
            if let particleFilter = self.particleFilter {
                
                let poses = particleFilter.estimatedPath
                
                // convert particles to right size
                return poses.map({p in self.transformParticle(p, ToMapCS: map)})
            }
        }
        return []
    }
    
    func estimatedMotionPathForParticleMapView(view: ParticleMapView) -> [Pose] {
        if let map = self.map {
            if let particleFilter = self.particleFilter {
                
                let poses = particleFilter.motionPath
                
                // convert particles to right size
                return poses.map({p in self.transformParticle(p, ToMapCS: map)})
            }
        }
        return []
    }
    
    func landmarkForParticleMapView(view: ParticleMapView) -> [Landmark] {
        if let map = self.map {
            return map.landmarks.values.array.map({l in self.transformLandmark(landmark: l, ToMapCS: map)})
        }
        return []
    }
    
    func particleSetMeanForParticleMapView(view: ParticleMapView) -> (x: Double, y: Double) {
        if let map = self.map {
            if let particleFilter = self.particleFilter {
                return transformPose(particleFilter.particleSetMean, ToMapCS: map)
            }
        }
        return (x: -1, y: -1)
    }
    
    // from Meters to pixels
    private func transformParticle(p: Particle, ToMapCS map: Map) -> Particle{
        let x = p.x * Double(map.scale)
        let y = p.y * Double(map.scale)
        let theta = p.theta // map orientation already integrated in MotionModel
        
        return Particle(x: x, y: y, theta: theta)
    }
    
    // from Meters to pixels
    private func transformLandmark(landmark l: Landmark, ToMapCS map: Map) -> Landmark {
        let xNew = l.x * Double(map.scale)
        let yNew = l.y * Double(map.scale)
        
        return Landmark(uuid: l.uuid, major: l.major, minor: l.minor, x: xNew, y: yNew)
    }
    
    private func transformPose(p: (x:Double, y: Double), ToMapCS map: Map) -> (x: Double, y: Double) {
        return (x: p.x * Double(map.scale), y: p.y * Double(map.scale))
    }
    
    
    // MARK: UIScrollView delegate
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return self.particleMapView
    }

}