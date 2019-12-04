import Foundation
import UIKit
import AsyncDisplayKit

private let motionAmount: CGFloat = 32.0

public final class WallpaperBackgroundNode: ASDisplayNode {
    let contentNode: ASDisplayNode
    
    public var motionEnabled: Bool = false {
        didSet {
            if oldValue != self.motionEnabled {
                if self.motionEnabled {
                    let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
                    horizontal.minimumRelativeValue = motionAmount
                    horizontal.maximumRelativeValue = -motionAmount
                    
                    let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
                    vertical.minimumRelativeValue = motionAmount
                    vertical.maximumRelativeValue = -motionAmount
                    
                    let group = UIMotionEffectGroup()
                    group.motionEffects = [horizontal, vertical]
                    self.contentNode.view.addMotionEffect(group)
                } else {
                    for effect in self.contentNode.view.motionEffects {
                        self.contentNode.view.removeMotionEffect(effect)
                    }
                }
                if !self.frame.isEmpty {
                    self.updateScale()
                }
            }
        }
    }
    
    public var image: UIImage? {
        didSet {
            self.contentNode.contents = self.image?.cgImage
        }
    }
    
    public var imageContentMode: UIView.ContentMode {
        didSet {
            self.contentNode.contentMode = self.imageContentMode
        }
    }
    
    func updateScale() {
        if self.motionEnabled {
            let scale = (self.frame.width + motionAmount * 2.0) / self.frame.width
            self.contentNode.transform = CATransform3DMakeScale(scale, scale, 1.0)
        } else {
            self.contentNode.transform = CATransform3DIdentity
        }
    }
    
    public override init() {
        self.imageContentMode = .scaleAspectFill
        
        self.contentNode = ASDisplayNode()
        self.contentNode.contentMode = self.imageContentMode
        
        super.init()
        
        self.clipsToBounds = true
        self.contentNode.frame = self.bounds
        self.addSubnode(self.contentNode)
    }
    
    public func updateLayout(size: CGSize, transition: ContainedViewLayoutTransition) {
        let isFirstLayout = self.frame.isEmpty
        transition.updatePosition(node: self.contentNode, position: CGPoint(x: size.width / 2.0, y: size.height / 2.0))
        transition.updateBounds(node: self.contentNode, bounds: CGRect(origin: CGPoint(), size: size))
        
        if isFirstLayout && !self.frame.isEmpty {
            self.updateScale()
        }
    }
}
