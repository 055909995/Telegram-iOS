import Foundation
import UIKit
import AsyncDisplayKit

final class TooltipControllerNode: ASDisplayNode {
    private let dismiss: () -> Void
    
    private var validLayout: ContainerViewLayout?
    
    private let containerNode: ContextMenuContainerNode
    private let textNode: ImmediateTextNode
    
    var sourceRect: CGRect?
    var arrowOnBottom: Bool = true
    
    private var dismissedByTouchOutside = false
    
    init(text: String, dismiss: @escaping () -> Void) {
        self.containerNode = ContextMenuContainerNode()
        self.containerNode.backgroundColor = UIColor(white: 0.0, alpha: 0.8)
        
        self.textNode = ImmediateTextNode()
        self.textNode.attributedText = NSAttributedString(string: text, font: Font.regular(14.0), textColor: .white, paragraphAlignment: .center)
        self.textNode.isLayerBacked = true
        self.textNode.displaysAsynchronously = false
        
        self.dismiss = dismiss
        
        super.init()
        
        self.containerNode.addSubnode(self.textNode)
        
        self.addSubnode(self.containerNode)
    }
    
    func updateText(_ text: String, transition: ContainedViewLayoutTransition) {
        if transition.isAnimated, let copyLayer = self.textNode.layer.snapshotContentTree() {
            copyLayer.frame = self.textNode.layer.frame
            self.textNode.layer.superlayer?.addSublayer(copyLayer)
            transition.updateAlpha(layer: copyLayer, alpha: 0.0, completion: { [weak copyLayer] _ in
                copyLayer?.removeFromSuperlayer()
            })
            self.textNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.12)
        }
        self.textNode.attributedText = NSAttributedString(string: text, font: Font.regular(14.0), textColor: .white, paragraphAlignment: .center)
        if let layout = self.validLayout {
            self.containerLayoutUpdated(layout, transition: transition)
        }
    }
    
    func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        self.validLayout = layout
        
        let maxActionsWidth = layout.size.width - 20.0
        
        var textSize = self.textNode.updateLayout(CGSize(width: maxActionsWidth, height: CGFloat.greatestFiniteMagnitude))
        textSize.width = ceil(textSize.width / 2.0) * 2.0
        textSize.height = ceil(textSize.height / 2.0) * 2.0
        let contentSize = CGSize(width: textSize.width + 12.0, height: textSize.height + 34.0)
        
        let sourceRect: CGRect = self.sourceRect ?? CGRect(origin: CGPoint(x: layout.size.width / 2.0, y: layout.size.height / 2.0), size: CGSize())
        
        let insets = layout.insets(options: [.statusBar, .input])
        
        let verticalOrigin: CGFloat
        var arrowOnBottom = true
        if sourceRect.minY - 54.0 > insets.top {
            verticalOrigin = sourceRect.minY - contentSize.height
        } else {
            verticalOrigin = min(layout.size.height - insets.bottom - contentSize.height, sourceRect.maxY)
            arrowOnBottom = false
        }
        self.arrowOnBottom = arrowOnBottom
        
        let horizontalOrigin: CGFloat = floor(min(max(8.0, sourceRect.midX - contentSize.width / 2.0), layout.size.width - contentSize.width - 8.0))
        
        transition.updateFrame(node: self.containerNode, frame: CGRect(origin: CGPoint(x: horizontalOrigin, y: verticalOrigin), size: contentSize))
        self.containerNode.relativeArrowPosition = (sourceRect.midX - horizontalOrigin, arrowOnBottom)
        
        self.containerNode.updateLayout(transition: transition)
        
        let textFrame = CGRect(origin: CGPoint(x: 6.0, y: 17.0), size: textSize)
        if transition.isAnimated, textFrame.size != self.textNode.frame.size {
            transition.animatePositionAdditive(node: self.textNode, offset: CGPoint(x: textFrame.minX - self.textNode.frame.minX, y: 0.0))
        }
        self.textNode.frame = textFrame
    }
    
    func animateIn() {
        self.containerNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.1)
    }
    
    func animateOut(completion: @escaping () -> Void) {
        self.containerNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.3, removeOnCompletion: false, completion: { _ in
            completion()
        })
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let event = event {
            var eventIsPresses = false
            if #available(iOSApplicationExtension 9.0, *) {
                eventIsPresses = event.type == .presses
            }
            if event.type == .touches || eventIsPresses {
                if self.containerNode.frame.contains(point) {
                    if !self.dismissedByTouchOutside {
                        self.dismissedByTouchOutside = true
                        self.dismiss()
                    }
                }
                return nil
            }
        }
        return super.hitTest(point, with: event)
    }
}

