import Foundation
import Display
import AsyncDisplayKit
import LegacyComponents

private final class RadialProgressContentCancelNodeParameters: NSObject {
    let color: UIColor
    let displayCancel: Bool
    
    init(color: UIColor, displayCancel: Bool) {
        self.color = color
        self.displayCancel = displayCancel
    }
}

private final class RadialProgressContentSpinnerNodeParameters: NSObject {
    let color: UIColor
    let progress: CGFloat
    
    init(color: UIColor, progress: CGFloat) {
        self.color = color
        self.progress = progress
    }
}

private final class RadialProgressContentSpinnerNode: ASDisplayNode {
    var progressAnimationCompleted: (() -> Void)?
    
    var color: UIColor {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    private var effectiveProgress: CGFloat = 0.0 {
        didSet {
            self.setNeedsDisplay()
        }
    }

    var progress: CGFloat? {
        didSet {
            self.pop_removeAnimation(forKey: "progress")
            if let progress = self.progress {
                self.pop_removeAnimation(forKey: "indefiniteProgress")
                
                let animation = POPBasicAnimation()
                animation.property = POPAnimatableProperty.property(withName: "progress", initializer: { property in
                    property?.readBlock = { node, values in
                        values?.pointee = (node as! RadialProgressContentSpinnerNode).effectiveProgress
                    }
                    property?.writeBlock = { node, values in
                        (node as! RadialProgressContentSpinnerNode).effectiveProgress = values!.pointee
                    }
                    property?.threshold = 0.01
                }) as! POPAnimatableProperty
                animation.fromValue = CGFloat(self.effectiveProgress) as NSNumber
                animation.toValue = CGFloat(progress) as NSNumber
                animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
                animation.duration = 0.2
                animation.completionBlock = { [weak self] _, _ in
                    self?.progressAnimationCompleted?()
                }
                self.pop_add(animation, forKey: "progress")
            } else if self.pop_animation(forKey: "indefiniteProgress") == nil {
                let animation = POPBasicAnimation()
                animation.property = POPAnimatableProperty.property(withName: "progress", initializer: { property in
                    property?.readBlock = { node, values in
                        values?.pointee = (node as! RadialProgressContentSpinnerNode).effectiveProgress
                    }
                    property?.writeBlock = { node, values in
                        (node as! RadialProgressContentSpinnerNode).effectiveProgress = values!.pointee
                    }
                    property?.threshold = 0.01
                }) as! POPAnimatableProperty
                animation.fromValue = CGFloat(0.0) as NSNumber
                animation.toValue = CGFloat(2.0) as NSNumber
                animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
                animation.duration = 2.5
                animation.repeatForever = true
                self.pop_add(animation, forKey: "indefiniteProgress")
            }
        }
    }
    
    var isAnimatingProgress: Bool {
        return self.pop_animation(forKey: "progress") != nil
    }
    
    init(color: UIColor) {
        self.color = color
        
        super.init()
        
        self.isLayerBacked = true
        self.displaysAsynchronously = true
        self.isOpaque = false
    }
    
    override func drawParameters(forAsyncLayer layer: _ASDisplayLayer) -> NSObjectProtocol? {
        return RadialProgressContentSpinnerNodeParameters(color: self.color, progress: self.effectiveProgress)
    }
    
    @objc override class func draw(_ bounds: CGRect, withParameters parameters: Any?, isCancelled: () -> Bool, isRasterizing: Bool) {
        let context = UIGraphicsGetCurrentContext()!
        
        if !isRasterizing {
            context.setBlendMode(.copy)
            context.setFillColor(UIColor.clear.cgColor)
            context.fill(bounds)
        }
        
        if let parameters = parameters as? RadialProgressContentSpinnerNodeParameters {
            context.setStrokeColor(parameters.color.cgColor)
            
            let factor = bounds.size.width / 50.0
            
            var progress = parameters.progress
            var startAngle = -CGFloat.pi / 2.0
            var endAngle = CGFloat(progress) * 2.0 * CGFloat.pi + startAngle
            
            if progress > 1.0 {
                progress = 2.0 - progress
                let tmp = startAngle
                startAngle = endAngle
                endAngle = tmp
            }
            progress = min(1.0, progress)
            
            let lineWidth = max(1.6, 2.25 * factor)
            
            let pathDiameter = bounds.size.width - lineWidth - 2.5 * 2.0
            
            let path = UIBezierPath(arcCenter: CGPoint(x: bounds.size.width / 2.0, y: bounds.size.height / 2.0), radius: pathDiameter / 2.0, startAngle: startAngle, endAngle: endAngle, clockwise:true)
            path.lineWidth = lineWidth
            path.lineCapStyle = .round
            path.stroke()
        }
    }
    
    override func willEnterHierarchy() {
        super.willEnterHierarchy()
        
        let basicAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        basicAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        basicAnimation.duration = 2.0
        basicAnimation.fromValue = NSNumber(value: Float(0.0))
        basicAnimation.toValue = NSNumber(value: Float.pi * 2.0)
        basicAnimation.repeatCount = Float.infinity
        basicAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        basicAnimation.beginTime = 1.0
        
        self.layer.add(basicAnimation, forKey: "progressRotation")
    }
    
    override func didExitHierarchy() {
        super.didExitHierarchy()
        
        self.layer.removeAnimation(forKey: "progressRotation")
    }
}

private final class RadialProgressContentCancelNode: ASDisplayNode {
    var color: UIColor {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    let displayCancel: Bool
    
    init(color: UIColor, displayCancel: Bool) {
        self.color = color
        self.displayCancel = displayCancel
        
        super.init()
        
        self.isLayerBacked = true
        self.displaysAsynchronously = true
        self.isOpaque = false
    }
    
    override func drawParameters(forAsyncLayer layer: _ASDisplayLayer) -> NSObjectProtocol? {
        return RadialProgressContentCancelNodeParameters(color: self.color, displayCancel: self.displayCancel)
    }
    
    @objc override class func draw(_ bounds: CGRect, withParameters parameters: Any?, isCancelled: () -> Bool, isRasterizing: Bool) {
        let context = UIGraphicsGetCurrentContext()!
        
        if !isRasterizing {
            context.setBlendMode(.copy)
            context.setFillColor(UIColor.clear.cgColor)
            context.fill(bounds)
        }
        
        if let parameters = parameters as? RadialProgressContentCancelNodeParameters {
            if parameters.displayCancel {
                let diameter = min(bounds.size.width, bounds.size.height)
                
                let factor = diameter / 50.0
                
                context.setStrokeColor(parameters.color.cgColor)
                context.setLineWidth(max(1.6, 2.0 * factor))
                context.setLineCap(.round)
                
                let crossSize: CGFloat = 14.0 * factor
                context.move(to: CGPoint(x: diameter / 2.0 - crossSize / 2.0, y: diameter / 2.0 - crossSize / 2.0))
                context.addLine(to: CGPoint(x: diameter / 2.0 + crossSize / 2.0, y: diameter / 2.0 + crossSize / 2.0))
                context.strokePath()
                context.move(to: CGPoint(x: diameter / 2.0 + crossSize / 2.0, y: diameter / 2.0 - crossSize / 2.0))
                context.addLine(to: CGPoint(x: diameter / 2.0 - crossSize / 2.0, y: diameter / 2.0 + crossSize / 2.0))
                context.strokePath()
            }
        }
    }
}

final class RadialProgressContentNode: RadialStatusContentNode {
    private let spinnerNode: RadialProgressContentSpinnerNode
    private let cancelNode: RadialProgressContentCancelNode
    
    var color: UIColor {
        didSet {
            self.setNeedsDisplay()
            self.spinnerNode.color = self.color
        }
    }
    
    var progress: CGFloat? = 0.0 {
        didSet {
            self.spinnerNode.progress = self.progress
        }
    }
    
    let displayCancel: Bool
    
    private var enqueuedReadyForTransition: (() -> Void)?
    
    init(color: UIColor, displayCancel: Bool) {
        self.color = color
        self.displayCancel = displayCancel
        
        self.spinnerNode = RadialProgressContentSpinnerNode(color: color)
        self.cancelNode = RadialProgressContentCancelNode(color: color, displayCancel: displayCancel)
        
        super.init()
        
        self.isLayerBacked = true
        
        self.addSubnode(self.spinnerNode)
        self.addSubnode(self.cancelNode)
        
        self.spinnerNode.progressAnimationCompleted = { [weak self] in
            if let strongSelf = self {
                if let enqueuedReadyForTransition = strongSelf.enqueuedReadyForTransition {
                    strongSelf.enqueuedReadyForTransition = nil
                    enqueuedReadyForTransition()
                }
            }
        }
    }
    
    override func enqueueReadyForTransition(_ f: @escaping () -> Void) {
        if self.spinnerNode.isAnimatingProgress {
            self.enqueuedReadyForTransition = f
        } else {
            f()
        }
    }
    
    override func layout() {
        super.layout()
        
        let bounds = self.bounds
        self.spinnerNode.bounds = bounds
        self.spinnerNode.position = CGPoint(x: bounds.width / 2.0, y: bounds.height / 2.0)
        self.cancelNode.frame = bounds
    }
    
   override func animateOut(completion: @escaping () -> Void) {
        self.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.15, removeOnCompletion: false, completion: { _ in
            completion()
        })
        self.cancelNode.layer.animateScale(from: 1.0, to: 0.3, duration: 0.15, removeOnCompletion: false)
    }
    
    override func animateIn() {
        self.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.15)
        self.cancelNode.layer.animateScale(from: 0.3, to: 1.0, duration: 0.15)
    }
}
