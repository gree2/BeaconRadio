//
//  ParticleView.swift
//  BeaconRadio
//
//  Created by Thomas Bopst on 31/10/14.
//  Copyright (c) 2014 Thomas Bopst. All rights reserved.
//


class ParticleMapView: UIView {
    
    // MARK: Initializer
    override init() {
        super.init()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    // MARK: View's methods
    var dataSource: ParticleMapViewDataSource?
    
    override func drawRect(rect: CGRect) {
        if let dataSource = self.dataSource {
            if let mapImg = dataSource.mapImgForParticleMapView(self) {
                let particles = dataSource.particlesForParticleMapView(self)
                let path = dataSource.estimatedPathForParticleMapView(self)
                let landmarks = dataSource.landmarkForParticleMapView(self)
                let image = drawParticleMapImgWith(Map: mapImg, particles: particles, poses: path, landmarks: landmarks)
                
                
                let xScale = self.bounds.size.width / image.size.width
                let yScale = self.bounds.size.height / image.size.height
                
                let scale = min(xScale, yScale)
                
                let imgSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
                
                let offsetX = (self.bounds.size.width - imgSize.width) / 2
                let offsetY = (self.bounds.size.height - imgSize.height) / 2
                
                
                let imgRect = CGRect(origin: CGPoint(x: offsetX, y: offsetY), size: imgSize)
                
                
                let context = UIGraphicsGetCurrentContext()
                
                CGContextDrawImage(context, imgRect, image.CGImage)
            }
        }
    }
    
    // MARK: ParticleMapImg drawing
    var particleSize: Double = 20.0 {
        didSet {
            if self.particleSize > 0 {
                self.particleSize = oldValue
            }
        }
    }
    
    private var arrowHeadAngle: Double {
        get {
            return M_PI_2 // = Angle.deg2Rad(90)
        }
    }
    
    private var arrowHeadSize: Double {
        get {
            return self.particleSize * 0.3
        }
    }
    
    var lineWidth: Double = 1.0 {
        didSet {
            if self.lineWidth < 1.0 {
                self.lineWidth = 1.0
            }
        }
    }
    
    var landmarkSize: Double = 10.0 {
        didSet {
            if self.particleSize > 0 {
                self.particleSize = oldValue
            }
        }
    }
    
    private func drawParticleMapImgWith(Map mapImg: UIImage, particles: [Particle], poses: [Pose], landmarks: [Landmark]) -> UIImage {
        
        var particleMapImg = mapImg
        
        UIGraphicsBeginImageContext(mapImg.size) // IMPORTANT NOTE: ImageContext -> Point (0,0) in lower left corner!
        
        // draw map image
        mapImg.drawAtPoint(CGPoint.zeroPoint)
        
        // draw particles
        for particle in particles {
            if isParticleInRect(particle, rect: CGRect(origin: CGPoint.zeroPoint, size: mapImg.size)) {
                drawParticle(particle)
            } else {
                println("[Warning] ParticleMapView: Particle (\(particle.description())) out of Bounds")
            }
        }
        
        
        if !landmarks.isEmpty {
            let context = UIGraphicsGetCurrentContext()
            CGContextSetStrokeColorWithColor(context, UIColor.blueColor().CGColor)
            
            for l in landmarks {
                let circleRect = CGRect(x: l.x - self.landmarkSize * 0.5, y: l.y - self.landmarkSize * 0.5, width: self.landmarkSize, height: self.landmarkSize)
                
                CGContextFillEllipseInRect(context, circleRect)
                CGContextStrokeEllipseInRect(context, circleRect)
            }
        }
        
        // draw estimated path
        if !poses.isEmpty {
            let context = UIGraphicsGetCurrentContext()
            CGContextSetStrokeColorWithColor(context, UIColor.blackColor().CGColor)
            CGContextSetLineDash(context, 0, [6.0, 5.0], 2)
            CGContextSetLineWidth(context, CGFloat(self.lineWidth))
            
            CGContextBeginPath(context)
            
            let first = poses.first!
            
            CGContextMoveToPoint(context, CGFloat(first.x), CGFloat(first.y))
//            CGContextAddEllipseInRect(context, CGRect(x: p.x, y: p.y, width: 10, height: 10))
            
            for var i = 1; i < poses.count; ++i {
                let p = poses[i]
                CGContextAddLineToPoint(context, CGFloat(p.x), CGFloat(p.y))
//                CGContextAddEllipseInRect(context, CGRect(x: p.x, y: p.y, width: 10, height: 10))
            }
            
            CGContextDrawPath(context, kCGPathStroke)
        }
        
        particleMapImg = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return particleMapImg
    }
    
    private func isParticleInRect(particle:Particle, rect:CGRect) -> Bool {
        
        let tail = pointOfParticleTail(particle)
        let head = centerPointOfParticleHead(particle)
        let right = rightPointOfParticleHead(head: head, particle: particle)
        let left = leftPointOfParticleHead(head: head, particle: particle)
        
        return CGRectContainsPoint(rect, tail) && CGRectContainsPoint(rect, head) && CGRectContainsPoint(rect, right) && CGRectContainsPoint(rect, left)
    }
    
    private func drawParticle(particle: Particle) {
        
        let tail = pointOfParticleTail(particle)
        let head = centerPointOfParticleHead(particle)
        let right = rightPointOfParticleHead(head: head, particle: particle)
        let left = leftPointOfParticleHead(head: head, particle: particle)

        // DEBUG println("Particle angle: \(Angle.unitCircleRad2CompassDeg(particle.theta)) compassDeg (\(particle.theta) rad)")
        
        // drawing code goes here
        let context = UIGraphicsGetCurrentContext()
        CGContextSetStrokeColorWithColor(context, UIColor.redColor().CGColor)
        CGContextSetLineWidth(context, CGFloat(self.lineWidth))
        
        CGContextBeginPath(context)
        CGContextMoveToPoint(context, tail.x, tail.y)
        CGContextAddLineToPoint(context, head.x, head.y)
        CGContextAddLineToPoint(context, right.x, right.y)
        
        CGContextMoveToPoint(context, head.x, head.y)
        CGContextAddLineToPoint(context, left.x, left.y)
        
        CGContextDrawPath(context, kCGPathStroke)
        
    }
    
    private func pointOfParticleTail(particle: Particle) -> CGPoint {
        let angle = (particle.theta + M_PI) % (2 * M_PI)
        
        return pointFrom(point: CGPoint(x: particle.x, y: particle.y), withDistance: (self.particleSize * 0.5), andAngle: angle)
    }
    
    private func centerPointOfParticleHead(particle: Particle) -> CGPoint {
        let angle = particle.theta

        return pointFrom(point: CGPoint(x: particle.x, y: particle.y), withDistance: (self.particleSize * 0.5), andAngle: angle)
    }
    
    private func leftPointOfParticleHead(head point: CGPoint, particle: Particle) -> CGPoint {
        var angle = (particle.theta - self.arrowHeadAngle/2 - M_PI) % (2 * M_PI)
        
        if angle < 0 {
            angle += 2 * M_PI
        }
        
        return pointFrom(point: point, withDistance: self.arrowHeadSize, andAngle: angle)
    }
    
    private func rightPointOfParticleHead(head point: CGPoint, particle: Particle) -> CGPoint {
        var angle = (particle.theta + self.arrowHeadAngle/2 + M_PI) % (2 * M_PI)
        
        if angle < 0 {
            angle += 2 * M_PI
        }
        
        return pointFrom(point: point, withDistance: self.arrowHeadSize, andAngle: angle)
    }
    
    private func pointFrom(point p: CGPoint, withDistance d: Double, andAngle alpha: Double) -> CGPoint {
        let deltaX = cos(alpha) * d
        let deltaY = sin(alpha) * d
        
        let x = Double(p.x) + deltaX
        let y = Double(p.y) + deltaY
        
        return CGPoint(x: x, y: y)
    }
    
}

protocol ParticleMapViewDataSource {
    func mapImgForParticleMapView(view: ParticleMapView) -> UIImage?
    func particlesForParticleMapView(view: ParticleMapView) -> [Particle]
    func estimatedPathForParticleMapView(view: ParticleMapView) -> [Pose]
    func landmarkForParticleMapView(view: ParticleMapView) -> [Landmark]
}
