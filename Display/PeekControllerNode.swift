import Foundation
import AsyncDisplayKit

final class PeekControllerNode: ViewControllerTracingNode {
    private let requestDismiss: () -> Void
    
    private let theme: PeekControllerTheme
    
    private let blurView: UIView
    private let dimNode: ASDisplayNode
    private let containerBackgroundNode: ASImageNode
    private let containerNode: ASDisplayNode
    
    private var validLayout: ContainerViewLayout?
    private var containerOffset: CGFloat = 0.0
    private var panInitialContainerOffset: CGFloat?
    
    private var content: PeekControllerContent
    private var contentNode: PeekControllerContentNode & ASDisplayNode
    private var contentNodeHasValidLayout = false
    
    private var menuNode: PeekControllerMenuNode?
    private var displayingMenu = false
    
    private var hapticFeedback: HapticFeedback?
    
    init(theme: PeekControllerTheme, content: PeekControllerContent, requestDismiss: @escaping () -> Void) {
        self.theme = theme
        self.requestDismiss = requestDismiss
        
        self.dimNode = ASDisplayNode()
        self.blurView = UIVisualEffectView(effect: UIBlurEffect(style: theme.isDark ? .dark : .light))
        self.blurView.isUserInteractionEnabled = false
        
        switch content.menuActivation() {
            case .drag:
                self.dimNode.backgroundColor = nil
                self.blurView.alpha = 1.0
            case .press:
                self.dimNode.backgroundColor = UIColor(white: theme.isDark ? 0.0 : 1.0, alpha: 0.5)
                self.blurView.alpha = 0.0
        }
        
        self.containerBackgroundNode = ASImageNode()
        self.containerBackgroundNode.isLayerBacked = true
        self.containerBackgroundNode.displayWithoutProcessing = true
        self.containerBackgroundNode.displaysAsynchronously = false
        
        self.containerNode = ASDisplayNode()
        
        self.content = content
        self.contentNode = content.node()
        
        var activatedActionImpl: (() -> Void)?
        let menuItems = content.menuItems()
        if menuItems.isEmpty {
            self.menuNode = nil
        } else {
            self.menuNode = PeekControllerMenuNode(theme: theme, items: menuItems, activatedAction: {
                activatedActionImpl?()
            })
        }
        
        super.init()
        
        if content.presentation() == .freeform {
            self.containerNode.isUserInteractionEnabled = false
        } else {
            self.containerNode.clipsToBounds = true
            self.containerNode.cornerRadius = 16.0
        }
        
        self.addSubnode(self.dimNode)
        self.view.addSubview(self.blurView)
        self.containerNode.addSubnode(self.contentNode)
        self.addSubnode(self.containerNode)
        
        if let menuNode = self.menuNode {
            self.addSubnode(menuNode)
        }
        
        activatedActionImpl = { [weak self] in
            self?.requestDismiss()
        }
        
        self.hapticFeedback = HapticFeedback()
        self.hapticFeedback?.prepareTap()
    }
    
    deinit {
    }
    
    override func didLoad() {
        super.didLoad()
        
        self.dimNode.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.dimNodeTap(_:))))
        self.view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.panGesture(_:))))
    }
    
    func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        self.validLayout = layout
        
        transition.updateFrame(node: self.dimNode, frame: CGRect(origin: CGPoint(), size: layout.size))
        transition.updateFrame(view: self.blurView, frame: CGRect(origin: CGPoint(), size: layout.size))
        
        let layoutInsets = layout.insets(options: [])
        let maxContainerSize = CGSize(width: layout.size.width - 14.0 * 2.0, height: layout.size.height - layoutInsets.top - layoutInsets.bottom - 90.0)
        
        var menuSize: CGSize?
        
        let contentSize = self.contentNode.updateLayout(size: maxContainerSize, transition: self.contentNodeHasValidLayout ? transition : .immediate)
        if self.contentNodeHasValidLayout {
            transition.updateFrame(node: self.contentNode, frame: CGRect(origin: CGPoint(), size: contentSize))
        } else {
            self.contentNode.frame = CGRect(origin: CGPoint(), size: contentSize)
        }
        
        var containerFrame: CGRect
        switch self.content.presentation() {
            case .contained:
                containerFrame = CGRect(origin: CGPoint(x: floor((layout.size.width - contentSize.width) / 2.0), y: self.containerOffset + floor((layout.size.height - contentSize.height) / 2.0)), size: contentSize)
            case .freeform:
                containerFrame = CGRect(origin: CGPoint(x: floor((layout.size.width - contentSize.width) / 2.0), y: self.containerOffset + floor((layout.size.height - contentSize.height) / 4.0)), size: contentSize)
        }
        
        if let menuNode = self.menuNode {
            let menuWidth = layout.size.width - layoutInsets.left - layoutInsets.right - 14.0 * 2.0
            let menuHeight = menuNode.updateLayout(width: menuWidth, transition: transition)
            menuSize = CGSize(width: menuWidth, height: menuHeight)
            
            if self.displayingMenu {
                let upperBound = layout.size.height - layoutInsets.bottom - menuHeight - 14.0 * 2.0 - containerFrame.height
                if containerFrame.origin.y > upperBound {
                    var offset = upperBound - containerFrame.origin.y
                    let delta = abs(offset)
                    let factor: CGFloat = 60.0
                    offset = (-((1.0 - (1.0 / (((delta) * 0.55 / (factor)) + 1.0))) * factor)) * (offset < 0.0 ? 1.0 : -1.0)
                    containerFrame.origin.y = upperBound - offset
                }
                
                transition.updateAlpha(layer: self.blurView.layer, alpha: 1.0)
            }
        }
        
        transition.updateFrame(node: self.containerNode, frame: containerFrame)
        
        if let menuNode = self.menuNode, let menuSize = menuSize {
            let menuY: CGFloat
            if self.displayingMenu {
                menuY = max(containerFrame.maxY + 14.0, layout.size.height - layoutInsets.bottom - 14.0 - menuSize.height)
            } else {
                menuY = layout.size.height + 14.0
            }
            
            let menuFrame = CGRect(origin: CGPoint(x: floor((layout.size.width - menuSize.width) / 2.0), y: menuY), size: menuSize)
            
            if self.contentNodeHasValidLayout {
                transition.updateFrame(node: menuNode, frame: menuFrame)
            } else {
                menuNode.frame = menuFrame
            }
        }
        
        self.contentNodeHasValidLayout = true
    }
    
    func animateIn(from rect: CGRect) {
        self.dimNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.3)
        self.blurView.layer.animateAlpha(from: 0.0, to: self.blurView.alpha, duration: 0.3)
        
        self.containerNode.layer.animateSpring(from: NSValue(cgPoint: CGPoint(x: rect.midX - self.containerNode.position.x, y: rect.midY - self.containerNode.position.y)), to: NSValue(cgPoint: CGPoint()), keyPath: "position", duration: 0.4, initialVelocity: 0.0, damping: 110.0, additive: true)
        self.containerNode.layer.animateSpring(from: 0.1 as NSNumber, to: 1.0 as NSNumber, keyPath: "transform.scale", duration: 0.4, initialVelocity: 0.0, damping: 110.0)
        self.containerNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.15)
        
        if case .press = self.content.menuActivation() {
            self.hapticFeedback?.tap()
        } else {
            self.hapticFeedback?.impact()
        }
    }
    
    func animateOut(to rect: CGRect, completion: @escaping () -> Void) {
        self.dimNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false)
        self.blurView.layer.animateAlpha(from: self.blurView.alpha, to: 0.0, duration: 0.25, removeOnCompletion: false)
        self.containerNode.layer.animatePosition(from: CGPoint(), to: CGPoint(x: rect.midX - self.containerNode.position.x, y: rect.midY - self.containerNode.position.y), duration: 0.25, timingFunction: kCAMediaTimingFunctionEaseInEaseOut, removeOnCompletion: false, additive: true, force: true, completion: { _ in
            completion()
        })
        self.containerNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false)
        self.containerNode.layer.animateScale(from: 1.0, to: 0.1, duration: 0.25, removeOnCompletion: false)
        if let menuNode = self.menuNode {
            menuNode.layer.animatePosition(from: menuNode.position, to: CGPoint(x: menuNode.position.x, y: self.bounds.size.height + menuNode.bounds.size.height / 2.0), duration: 0.25, timingFunction: kCAMediaTimingFunctionEaseInEaseOut, removeOnCompletion: false)
        }
    }
    
    @objc func dimNodeTap(_ recognizer: UITapGestureRecognizer) {
        if case .ended = recognizer.state {
            self.requestDismiss()
        }
    }
    
    @objc func panGesture(_ recognizer: UIPanGestureRecognizer) {
        guard case .drag = self.content.menuActivation() else {
            return
        }
        
        switch recognizer.state {
            case .began:
                self.panInitialContainerOffset = self.containerOffset
            case .changed:
                if let panInitialContainerOffset = self.panInitialContainerOffset {
                    let translation = recognizer.translation(in: self.view)
                    var offset = panInitialContainerOffset + translation.y
                    if offset < 0.0 {
                        let delta = abs(offset)
                        let factor: CGFloat = 60.0
                        offset = (-((1.0 - (1.0 / (((delta) * 0.55 / (factor)) + 1.0))) * factor)) * (offset < 0.0 ? 1.0 : -1.0)
                    }
                    self.applyDraggingOffset(offset)
                }
            case .cancelled, .ended:
                if let _ = self.panInitialContainerOffset {
                    self.panInitialContainerOffset = nil
                    if self.containerOffset < 0.0 {
                        self.activateMenu()
                    } else {
                        self.requestDismiss()
                    }
                }
            default:
                break
        }
    }
    
    func applyDraggingOffset(_ offset: CGFloat) {
        self.containerOffset = offset
        if self.containerOffset < -25.0 {
            //self.displayingMenu = true
        } else {
            //self.displayingMenu = false
        }
        if let layout = self.validLayout {
            self.containerLayoutUpdated(layout, transition: .immediate)
        }
    }
    
    func activateMenu() {
        if case .press = self.content.menuActivation() {
            self.hapticFeedback?.impact()
        }
        if let layout = self.validLayout {
            self.displayingMenu = true
            self.containerOffset = 0.0
            self.containerLayoutUpdated(layout, transition: .animated(duration: 0.18, curve: .spring))
        }
    }
    
    func endDraggingWithVelocity(_ velocity: CGFloat) {
        if let _ = self.menuNode, velocity < -600.0 || self.containerOffset < -38.0 {
            if let layout = self.validLayout {
                self.displayingMenu = true
                self.containerOffset = 0.0
                self.containerLayoutUpdated(layout, transition: .animated(duration: 0.18, curve: .spring))
            }
        } else {
            self.requestDismiss()
        }
    }
    
    func updateContent(content: PeekControllerContent) {
        let contentNode = self.contentNode
        contentNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.15, removeOnCompletion: false, completion: { [weak contentNode] _ in
            contentNode?.removeFromSupernode()
        })
        contentNode.layer.animateScale(from: 1.0, to: 0.2, duration: 0.15, removeOnCompletion: false)
        
        self.menuNode?.removeFromSupernode()
        self.menuNode = nil
        
        self.content = content
        self.contentNode = content.node()
        self.containerNode.addSubnode(self.contentNode)
        self.contentNodeHasValidLayout = false
        
        var activatedActionImpl: (() -> Void)?
        let menuItems = content.menuItems()
        if menuItems.isEmpty {
            self.menuNode = nil
        } else {
            self.menuNode = PeekControllerMenuNode(theme: self.theme, items: menuItems, activatedAction: {
                activatedActionImpl?()
            })
        }
        
        if let menuNode = self.menuNode {
            self.addSubnode(menuNode)
        }
        
        activatedActionImpl = { [weak self] in
            self?.requestDismiss()
        }
        
        self.contentNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.1)
        self.contentNode.layer.animateSpring(from: 0.35 as NSNumber, to: 1.0 as NSNumber, keyPath: "transform.scale", duration: 0.5)
        
        if let layout = self.validLayout {
            self.containerLayoutUpdated(layout, transition: .animated(duration: 0.15, curve: .easeInOut))
        }
        
        self.hapticFeedback?.tap()
    }
}
