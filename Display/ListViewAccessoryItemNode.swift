import Foundation
import AsyncDisplayKit

public class ListViewAccessoryItemNode: ASDisplayNode {
    var transitionOffset: CGPoint = CGPoint() {
        didSet {
            self.bounds = CGRect(origin: self.transitionOffset, size: self.bounds.size)
        }
    }
    
    private var transitionOffsetAnimation: ListViewAnimation?
    
    final func animateTransitionOffset(from: CGPoint, beginAt: Double, duration: Double, curve: CGFloat -> CGFloat) {
        self.transitionOffset = from
        self.transitionOffsetAnimation = ListViewAnimation(from: from, to: CGPoint(), duration: duration, curve: curve, beginAt: beginAt, update: { [weak self] currentValue in
            if let strongSelf = self {
                strongSelf.transitionOffset = currentValue
            }
        })
    }
    
    final func removeAllAnimations() {
        self.transitionOffsetAnimation = nil
        self.transitionOffset = CGPoint()
    }
    
    final func animate(timestamp: Double) -> Bool {
        if let animation = self.transitionOffsetAnimation {
            animation.applyAt(timestamp)
                
            if animation.completeAt(timestamp) {
                self.transitionOffsetAnimation = nil
            } else {
                return true
            }
        }
    
        return false
    }
}
