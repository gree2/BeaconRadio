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
                //let mean = dataSource.particleSetMeanForParticleMapView(self)
                let path = dataSource.estimatedPathForParticleMapView(self)
                let motionPath = dataSource.estimatedMotionPathForParticleMapView(self)
                let landmarks = dataSource.landmarkForParticleMapView(self)
                let image = drawParticleMapImgWith(Map: mapImg, particles: particles, path: path, motionPath: motionPath, landmarks: landmarks)
                
                
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
    
    var pointSize: Double = 15.0 {
        didSet {
            if self.pointSize > 0 {
                self.pointSize = oldValue
            }
        }
    }
    
    private func drawParticleMapImgWith(Map mapImg: UIImage, particles: [Particle], path: [Pose], motionPath: [Pose], landmarks: [Landmark]) -> UIImage {
        
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
        
        // draw landmarks
        for l in landmarks {
            drawPoint(CGPoint(x: l.x, y: l.y), withColor: UIColor.blueColor())
        }
        
        // draw motion path
        self.drawPath(motionPath, withColor: UIColor.blackColor())
        
        // draw estimated path
        self.drawPath(path, withColor: UIColor.blueColor())
        
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
    
    private func drawPath(path: [Pose], withColor color: UIColor) {
        if !path.isEmpty {
            
            let context = UIGraphicsGetCurrentContext()
            CGContextSetStrokeColorWithColor(context, color.CGColor)
            CGContextSetLineDash(context, 0, [6.0, 5.0], 2)
            CGContextSetLineWidth(context, CGFloat(self.lineWidth))
            
            CGContextBeginPath(context)
            
            let first = path.first!
            let last = path.last!
            
            CGContextMoveToPoint(context, CGFloat(first.x), CGFloat(first.y))
            
            
            for var i = 1; i < path.count; ++i {
                let p = path[i]
                CGContextAddLineToPoint(context, CGFloat(p.x), CGFloat(p.y))
            }
            
            CGContextDrawPath(context, kCGPathStroke)
//            drawPoint(CGPoint(x: first.x, y: first.y), withColor: color)
            drawPoint(CGPoint(x: last.x, y: last.y), withColor: color)
        }
    }
    
    private func drawPoint(point: CGPoint, withColor color: UIColor) {
        if point.x >= 0 && point.y >= 0 {
            let ctx = UIGraphicsGetCurrentContext()
            CGContextSetFillColorWithColor(ctx, color.CGColor)
            
            let pointSize: CGFloat = CGFloat(self.pointSize)
            
            let circleRect = CGRect(x: point.x - pointSize * 0.5, y: point.y - pointSize * 0.5, width: pointSize, height: pointSize)
            CGContextFillEllipseInRect(ctx, circleRect)
        }

    }
    
}

protocol ParticleMapViewDataSource {
    func mapImgForParticleMapView(view: ParticleMapView) -> UIImage?
    func particlesForParticleMapView(view: ParticleMapView) -> [Particle]
    func estimatedPathForParticleMapView(view: ParticleMapView) -> [Pose]
    func landmarkForParticleMapView(view: ParticleMapView) -> [Landmark]
    func particleSetMeanForParticleMapView(view: ParticleMapView) -> (x: Double, y: Double)
    func estimatedMotionPathForParticleMapView(view: ParticleMapView) -> [Pose]
}
