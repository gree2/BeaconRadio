//
//  MapView.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 31/10/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//

import Foundation
import UIKit

class MapView: UIView, UIScrollViewDelegate {
    @IBOutlet private var view: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var mapImgView: UIImageView!
    
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        NSBundle.mainBundle().loadNibNamed("MapView", owner: self, options: nil)
        self.addSubview(self.view)
        scrollView.delegate = self
    }

    func showMap(mapImg: UIImage) {
        self.mapImgView.image = mapImg
        
        resetMapZoom()
        centerMap()
    }
    
    
    // MARK: UIScrollView delegate
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return self.containerView
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        centerMap()
    }
    
    // MARK: Helper methods
    private func resetMapZoom() {
        if let mapImg = self.mapImgView.image {

            // zoom
            let widthScale = self.scrollView.frame.width / mapImg.size.width
            let heightScale = self.scrollView.frame.width / mapImg.size.height
            
            let zoomScale = max(widthScale, heightScale)
            
            self.scrollView.setZoomScale(zoomScale, animated: false)
            self.scrollView.minimumZoomScale = zoomScale
        }
    }
    
    private func centerMap() {
        let offsetX:CGFloat = max((scrollView.bounds.size.width - scrollView.contentSize.width) / 2, 0.0)
        let offsetY:CGFloat = max((scrollView.bounds.size.height - scrollView.contentSize.height) / 2, 0.0)
        
        self.containerView.center = CGPoint(x: scrollView.contentSize.width / 2 + offsetX, y: scrollView.contentSize.height / 2 + offsetY);

    }
    
}