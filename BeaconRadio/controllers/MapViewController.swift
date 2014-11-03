//
//  MapViewController.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 30/10/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation

class MapViewController: UIViewController {
    
    private var map:Map?
    
    private var mapView:MapView {
        get {
            return self.view as MapView
        }
    }
    
    // MARK: UIViewController methods
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        let mapsManager = MapsManager()
        self.map = mapsManager.loadMap(name: "F007")
        
        if let mapImg = self.map?.mapImg {
            self.mapView.showMap(mapImg)
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: MapViewController methods
}