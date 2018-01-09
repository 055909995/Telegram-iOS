import UIKit
import AsyncDisplayKit

private var backArrowImageCache: [Int32: UIImage] = [:]

public final class NavigationBarTheme {
    public static func generateBackArrowImage(color: UIColor) -> UIImage? {
        return generateImage(CGSize(width: 13.0, height: 22.0), rotatedContext: { size, context in
            context.clear(CGRect(origin: CGPoint(), size: size))
            context.setFillColor(color.cgColor)
            
            context.translateBy(x: 0.0, y: -UIScreenPixel)
            
            let _ = try? drawSvgPath(context, path: "M3.60751322,11.5 L11.5468531,3.56066017 C12.1326395,2.97487373 12.1326395,2.02512627 11.5468531,1.43933983 C10.9610666,0.853553391 10.0113191,0.853553391 9.42553271,1.43933983 L0.449102936,10.4157696 C-0.149700979,11.0145735 -0.149700979,11.9854265 0.449102936,12.5842304 L9.42553271,21.5606602 C10.0113191,22.1464466 10.9610666,22.1464466 11.5468531,21.5606602 C12.1326395,20.9748737 12.1326395,20.0251263 11.5468531,19.4393398 L3.60751322,11.5 Z ")
        })
    }
    
    public let buttonColor: UIColor
    public let primaryTextColor: UIColor
    public let backgroundColor: UIColor
    public let separatorColor: UIColor
    public let badgeBackgroundColor: UIColor
    public let badgeStrokeColor: UIColor
    public let badgeTextColor: UIColor
    
    public init(buttonColor: UIColor, primaryTextColor: UIColor, backgroundColor: UIColor, separatorColor: UIColor, badgeBackgroundColor: UIColor, badgeStrokeColor: UIColor, badgeTextColor: UIColor) {
        self.buttonColor = buttonColor
        self.primaryTextColor = primaryTextColor
        self.backgroundColor = backgroundColor
        self.separatorColor = separatorColor
        self.badgeBackgroundColor = badgeBackgroundColor
        self.badgeStrokeColor = badgeStrokeColor
        self.badgeTextColor = badgeTextColor
    }
    
    public func withUpdatedSeparatorColor(_ color: UIColor) -> NavigationBarTheme {
        return NavigationBarTheme(buttonColor: self.buttonColor, primaryTextColor: self.primaryTextColor, backgroundColor: self.backgroundColor, separatorColor: color, badgeBackgroundColor: self.badgeBackgroundColor, badgeStrokeColor: self.badgeStrokeColor, badgeTextColor: self.badgeTextColor)
    }
}

private func backArrowImage(color: UIColor) -> UIImage? {
    var red: CGFloat = 0.0
    var green: CGFloat = 0.0
    var blue: CGFloat = 0.0
    var alpha: CGFloat = 0.0
    color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    
    let key = (Int32(alpha * 255.0) << 24) | (Int32(red * 255.0) << 16) | (Int32(green * 255.0) << 8) | Int32(blue * 255.0)
    if let image = backArrowImageCache[key] {
        return image
    } else {
        if let image = NavigationBarTheme.generateBackArrowImage(color: color) {
            backArrowImageCache[key] = image
            return image
        } else {
            return nil
        }
    }
}

open class NavigationBar: ASDisplayNode {
    private var theme: NavigationBarTheme
    
    private var validLayout: (CGSize, CGFloat, CGFloat)?
    private var requestedLayout: Bool = false
    
    var backPressed: () -> () = { }
    
    private var collapsed: Bool {
        get {
            return self.frame.size.height.isLess(than: 44.0)
        }
    }
    
    private let stripeNode: ASDisplayNode
    private let clippingNode: ASDisplayNode
    
    var contentNode: NavigationBarContentNode?
    
    private var itemTitleListenerKey: Int?
    private var itemTitleViewListenerKey: Int?
    
    private var itemLeftButtonListenerKey: Int?
    private var itemLeftButtonSetEnabledListenerKey: Int?
    
    private var itemRightButtonListenerKey: Int?
    private var itemRightButtonSetEnabledListenerKey: Int?
    
    private var itemBadgeListenerKey: Int?
    
    private var hintAnimateTitleNodeOnNextLayout: Bool = false
    
    private var _item: UINavigationItem?
    public var item: UINavigationItem? {
        get {
            return self._item
        } set(value) {
            if let previousValue = self._item {
                if let itemTitleListenerKey = self.itemTitleListenerKey {
                    previousValue.removeSetTitleListener(itemTitleListenerKey)
                    self.itemTitleListenerKey = nil
                }
                
                if let itemLeftButtonListenerKey = self.itemLeftButtonListenerKey {
                    previousValue.removeSetLeftBarButtonItemListener(itemLeftButtonListenerKey)
                    self.itemLeftButtonListenerKey = nil
                }
                
                if let itemLeftButtonSetEnabledListenerKey = self.itemLeftButtonSetEnabledListenerKey {
                    previousValue.leftBarButtonItem?.removeSetEnabledListener(itemLeftButtonSetEnabledListenerKey)
                    self.itemLeftButtonSetEnabledListenerKey = nil
                }
                
                if let itemRightButtonListenerKey = self.itemRightButtonListenerKey {
                    previousValue.removeSetRightBarButtonItemListener(itemRightButtonListenerKey)
                    self.itemRightButtonListenerKey = nil
                }
                
                if let itemRightButtonSetEnabledListenerKey = self.itemRightButtonSetEnabledListenerKey {
                    previousValue.rightBarButtonItem?.removeSetEnabledListener(itemRightButtonSetEnabledListenerKey)
                    self.itemRightButtonSetEnabledListenerKey = nil
                }
                
                if let itemBadgeListenerKey = self.itemBadgeListenerKey {
                    previousValue.removeSetBadgeListener(itemBadgeListenerKey)
                    self.itemBadgeListenerKey = nil
                }
            }
            self._item = value
            
            self.leftButtonNode.removeFromSupernode()
            self.rightButtonNode.removeFromSupernode()
            
            if let item = value {
                self.title = item.title
                self.itemTitleListenerKey = item.addSetTitleListener { [weak self] text, animated in
                    if let strongSelf = self {
                        let animateIn = animated && (strongSelf.title?.isEmpty ?? true)
                        strongSelf.title = text
                        if animateIn {
                            strongSelf.titleNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.25)
                        }
                    }
                }
                
                self.titleView = item.titleView
                self.itemTitleViewListenerKey = item.addSetTitleViewListener { [weak self] titleView in
                    if let strongSelf = self {
                        strongSelf.titleView = titleView
                    }
                }
                
                self.itemLeftButtonListenerKey = item.addSetLeftBarButtonItemListener { [weak self] previousItem, _, animated in
                    if let strongSelf = self {
                        if let itemLeftButtonSetEnabledListenerKey = strongSelf.itemLeftButtonSetEnabledListenerKey {
                            previousItem?.removeSetEnabledListener(itemLeftButtonSetEnabledListenerKey)
                            strongSelf.itemLeftButtonSetEnabledListenerKey = nil
                        }
                        
                        strongSelf.updateLeftButton(animated: animated)
                        strongSelf.invalidateCalculatedLayout()
                        strongSelf.requestLayout()
                    }
                }
                
                self.itemRightButtonListenerKey = item.addSetRightBarButtonItemListener { [weak self] previousItem, currentItem, animated in
                    if let strongSelf = self {
                        if let itemRightButtonSetEnabledListenerKey = strongSelf.itemRightButtonSetEnabledListenerKey {
                            previousItem?.removeSetEnabledListener(itemRightButtonSetEnabledListenerKey)
                            strongSelf.itemRightButtonSetEnabledListenerKey = nil
                        }
                        
                        if let currentItem = currentItem {
                            strongSelf.itemRightButtonSetEnabledListenerKey = currentItem.addSetEnabledListener { _ in
                                if let strongSelf = self {
                                    strongSelf.updateRightButton(animated: false)
                                }
                            }
                        }
                        
                        strongSelf.updateRightButton(animated: animated)
                        strongSelf.invalidateCalculatedLayout()
                        strongSelf.requestLayout()
                    }
                }
                
                self.itemBadgeListenerKey = item.addSetBadgeListener { [weak self] text in
                    if let strongSelf = self {
                        strongSelf.updateBadgeText(text: text)
                    }
                }
                self.updateBadgeText(text: item.badge)
                
                self.updateLeftButton(animated: false)
                self.updateRightButton(animated: false)
            } else {
                self.title = nil
                self.updateLeftButton(animated: false)
                self.updateRightButton(animated: false)
            }
            self.invalidateCalculatedLayout()
            self.requestLayout()
        }
    }
    
    private var title: String? {
        didSet {
            if let title = self.title {
                self.titleNode.attributedText = NSAttributedString(string: title, font: Font.bold(17.0), textColor: self.theme.primaryTextColor)
                if self.titleNode.supernode == nil {
                    self.clippingNode.addSubnode(self.titleNode)
                }
            } else {
                self.titleNode.removeFromSupernode()
            }
            
            self.invalidateCalculatedLayout()
            self.requestLayout()
        }
    }
    
    private var titleView: UIView? {
        didSet {
            if let oldValue = oldValue {
                oldValue.removeFromSuperview()
            }
            
            if let titleView = self.titleView {
                self.clippingNode.view.addSubview(titleView)
            }
            
            self.invalidateCalculatedLayout()
            self.requestLayout()
        }
    }
    
    private let titleNode: ASTextNode
    
    var previousItemListenerKey: Int?
    var previousItemBackListenerKey: Int?
    
    var _previousItem: UINavigationItem?
    var previousItem: UINavigationItem? {
        get {
            return self._previousItem
        } set(value) {
            if let previousValue = self._previousItem {
                if let previousItemListenerKey = self.previousItemListenerKey {
                    previousValue.removeSetTitleListener(previousItemListenerKey)
                    self.previousItemListenerKey = nil
                }
                if let previousItemBackListenerKey = self.previousItemBackListenerKey {
                    previousValue.removeSetBackBarButtonItemListener(previousItemBackListenerKey)
                    self.previousItemBackListenerKey = nil
                }
            }
            self._previousItem = value
            
            if let previousItem = value {
                self.previousItemListenerKey = previousItem.addSetTitleListener { [weak self] _, _ in
                    if let strongSelf = self, let previousItem = strongSelf.previousItem {
                        if let backBarButtonItem = previousItem.backBarButtonItem {
                            strongSelf.backButtonNode.text = backBarButtonItem.title ?? ""
                        } else {
                            strongSelf.backButtonNode.text = previousItem.title ?? ""
                        }
                        strongSelf.invalidateCalculatedLayout()
                        strongSelf.requestLayout()
                    }
                }
                
                self.previousItemBackListenerKey = previousItem.addSetBackBarButtonItemListener { [weak self] _, _, _ in
                    if let strongSelf = self, let previousItem = strongSelf.previousItem {
                        if let backBarButtonItem = previousItem.backBarButtonItem {
                            strongSelf.backButtonNode.text = backBarButtonItem.title ?? ""
                        } else {
                            strongSelf.backButtonNode.text = previousItem.title ?? ""
                        }
                        strongSelf.invalidateCalculatedLayout()
                        strongSelf.requestLayout()
                    }
                }
            }
            self.updateLeftButton(animated: false)
            
            self.invalidateCalculatedLayout()
            self.requestLayout()
        }
    }
    
    private func updateBadgeText(text: String?) {
        let actualText = text ?? ""
        if self.badgeNode.text != actualText {
            self.badgeNode.text = actualText
            self.badgeNode.isHidden = actualText.isEmpty
            
            self.invalidateCalculatedLayout()
            self.requestLayout()
        }
    }
    
    private func updateLeftButton(animated: Bool) {
        if let item = self.item {
            if let leftBarButtonItem = item.leftBarButtonItem, !leftBarButtonItem.backButtonAppearance {
                if animated {
                    if self.leftButtonNode.view.superview != nil {
                        if let snapshotView = self.leftButtonNode.view.snapshotContentTree() {
                            snapshotView.frame = self.leftButtonNode.frame
                            self.leftButtonNode.view.superview?.insertSubview(snapshotView, aboveSubview: self.leftButtonNode.view)
                            snapshotView.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.15, removeOnCompletion: false, completion: { [weak snapshotView] _ in
                                snapshotView?.removeFromSuperview()
                            })
                        }
                    }
                    
                    if self.backButtonNode.view.superview != nil {
                        if let snapshotView = self.backButtonNode.view.snapshotContentTree() {
                            snapshotView.frame = self.backButtonNode.frame
                            self.backButtonNode.view.superview?.insertSubview(snapshotView, aboveSubview: self.backButtonNode.view)
                            snapshotView.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.15, removeOnCompletion: false, completion: { [weak snapshotView] _ in
                                snapshotView?.removeFromSuperview()
                            })
                        }
                    }
                    
                    if self.backButtonArrow.view.superview != nil {
                        if let snapshotView = self.backButtonArrow.view.snapshotContentTree() {
                            snapshotView.frame = self.backButtonArrow.frame
                            self.backButtonArrow.view.superview?.insertSubview(snapshotView, aboveSubview: self.backButtonArrow.view)
                            snapshotView.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.15, removeOnCompletion: false, completion: { [weak snapshotView] _ in
                                snapshotView?.removeFromSuperview()
                            })
                        }
                    }
                    
                    if self.badgeNode.view.superview != nil {
                        if let snapshotView = self.badgeNode.view.snapshotContentTree() {
                            snapshotView.frame = self.badgeNode.frame
                            self.badgeNode.view.superview?.insertSubview(snapshotView, aboveSubview: self.badgeNode.view)
                            snapshotView.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.15, removeOnCompletion: false, completion: { [weak snapshotView] _ in
                                snapshotView?.removeFromSuperview()
                            })
                        }
                    }
                }
                
                self.backButtonNode.removeFromSupernode()
                self.backButtonArrow.removeFromSupernode()
                self.badgeNode.removeFromSupernode()
                
                self.leftButtonNode.text = leftBarButtonItem.title ?? ""
                self.leftButtonNode.bold = leftBarButtonItem.style == .done
                self.leftButtonNode.isEnabled = leftBarButtonItem.isEnabled
                if self.leftButtonNode.supernode == nil {
                    self.clippingNode.addSubnode(self.leftButtonNode)
                }
                
                if animated {
                    self.leftButtonNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.25)
                }
            } else {
                if animated {
                    if self.leftButtonNode.view.superview != nil {
                        if let snapshotView = self.leftButtonNode.view.snapshotContentTree() {
                            snapshotView.frame = self.leftButtonNode.frame
                            self.leftButtonNode.view.superview?.insertSubview(snapshotView, aboveSubview: self.leftButtonNode.view)
                            snapshotView.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.15, removeOnCompletion: false, completion: { [weak snapshotView] _ in
                                snapshotView?.removeFromSuperview()
                            })
                        }
                    }
                }
                self.leftButtonNode.removeFromSupernode()
                
                var backTitle: String?
                if let leftBarButtonItem = item.leftBarButtonItem, leftBarButtonItem.backButtonAppearance {
                    backTitle = leftBarButtonItem.title
                } else if let previousItem = self.previousItem {
                    if let backBarButtonItem = previousItem.backBarButtonItem {
                        backTitle = backBarButtonItem.title ?? "Back"
                    } else {
                        backTitle = previousItem.title ?? "Back"
                    }
                }
                
                if let backTitle = backTitle {
                    self.backButtonNode.text = backTitle
                    if self.backButtonNode.supernode == nil {
                        self.clippingNode.addSubnode(self.backButtonNode)
                        self.clippingNode.addSubnode(self.backButtonArrow)
                        self.clippingNode.addSubnode(self.badgeNode)
                    }
                    
                    if animated {
                        self.backButtonNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.25)
                        self.backButtonArrow.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.25)
                        self.badgeNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.25)
                    }
                } else {
                    self.backButtonNode.removeFromSupernode()
                }
            }
        } else {
            self.leftButtonNode.removeFromSupernode()
            self.backButtonNode.removeFromSupernode()
            self.backButtonArrow.removeFromSupernode()
            self.badgeNode.removeFromSupernode()
        }
        
        if animated {
            self.hintAnimateTitleNodeOnNextLayout = true
        }
    }
    
    private func updateRightButton(animated: Bool) {
        if let item = self.item {
            if let rightBarButtonItem = item.rightBarButtonItem {
                if animated, self.rightButtonNode.view.superview != nil {
                    if let snapshotView = self.rightButtonNode.view.snapshotContentTree() {
                        snapshotView.frame = self.rightButtonNode.frame
                        self.rightButtonNode.view.superview?.insertSubview(snapshotView, aboveSubview: self.rightButtonNode.view)
                        snapshotView.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.15, removeOnCompletion: false, completion: { [weak snapshotView] _ in
                            snapshotView?.removeFromSuperview()
                        })
                    }
                }
                self.rightButtonNode.text = rightBarButtonItem.title ?? ""
                self.rightButtonNode.image = rightBarButtonItem.image
                self.rightButtonNode.bold = rightBarButtonItem.style == .done
                self.rightButtonNode.isEnabled = rightBarButtonItem.isEnabled
                self.rightButtonNode.node = rightBarButtonItem.customDisplayNode
                if self.rightButtonNode.supernode == nil {
                    self.clippingNode.addSubnode(self.rightButtonNode)
                }
                if animated {
                    self.rightButtonNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.15)
                }
            } else {
                self.rightButtonNode.removeFromSupernode()
            }
        } else {
            self.rightButtonNode.removeFromSupernode()
        }
        
        if animated {
            self.hintAnimateTitleNodeOnNextLayout = true
        }
    }
    
    private let backButtonNode: NavigationButtonNode
    private let badgeNode: NavigationBarBadgeNode
    private let backButtonArrow: ASImageNode
    private let leftButtonNode: NavigationButtonNode
    private let rightButtonNode: NavigationButtonNode
    
    private var _transitionState: NavigationBarTransitionState?
    var transitionState: NavigationBarTransitionState? {
        get {
            return self._transitionState
        } set(value) {
            let updateNodes = self._transitionState?.navigationBar !== value?.navigationBar
            
            self._transitionState = value
            
            if updateNodes {
                if let transitionTitleNode = self.transitionTitleNode {
                    transitionTitleNode.removeFromSupernode()
                    self.transitionTitleNode = nil
                }
                
                if let transitionBackButtonNode = self.transitionBackButtonNode {
                    transitionBackButtonNode.removeFromSupernode()
                    self.transitionBackButtonNode = nil
                }
                
                if let transitionBackArrowNode = self.transitionBackArrowNode {
                    transitionBackArrowNode.removeFromSupernode()
                    self.transitionBackArrowNode = nil
                }
                
                if let transitionBadgeNode = self.transitionBadgeNode {
                    transitionBadgeNode.removeFromSupernode()
                    self.transitionBadgeNode = nil
                }

                if let value = value {
                    switch value.role {
                        case .top:
                            if let transitionTitleNode = value.navigationBar?.makeTransitionTitleNode(foregroundColor: self.theme.primaryTextColor) {
                                self.transitionTitleNode = transitionTitleNode
                                if self.leftButtonNode.supernode != nil {
                                    self.clippingNode.insertSubnode(transitionTitleNode, belowSubnode: self.leftButtonNode)
                                } else if self.backButtonNode.supernode != nil {
                                    self.clippingNode.insertSubnode(transitionTitleNode, belowSubnode: self.backButtonNode)
                                } else {
                                    self.clippingNode.addSubnode(transitionTitleNode)
                                }
                            }
                        case .bottom:
                            if let transitionBackButtonNode = value.navigationBar?.makeTransitionBackButtonNode(accentColor: self.theme.buttonColor) {
                                self.transitionBackButtonNode = transitionBackButtonNode
                                self.clippingNode.addSubnode(transitionBackButtonNode)
                            }
                            if let transitionBackArrowNode = value.navigationBar?.makeTransitionBackArrowNode(accentColor: self.theme.buttonColor) {
                                self.transitionBackArrowNode = transitionBackArrowNode
                                self.clippingNode.addSubnode(transitionBackArrowNode)
                            }
                            if let transitionBadgeNode = value.navigationBar?.makeTransitionBadgeNode() {
                                self.transitionBadgeNode = transitionBadgeNode
                                self.clippingNode.addSubnode(transitionBadgeNode)
                            }
                    }
                }
            }
            
            self.requestedLayout = true
            self.layout()
        }
    }
    
    private var transitionTitleNode: ASDisplayNode?
    private var transitionBackButtonNode: NavigationButtonNode?
    private var transitionBackArrowNode: ASDisplayNode?
    private var transitionBadgeNode: ASDisplayNode?
    
    public init(theme: NavigationBarTheme) {
        self.theme = theme
        self.stripeNode = ASDisplayNode()
        
        self.titleNode = ASTextNode()
        self.backButtonNode = NavigationButtonNode()
        self.badgeNode = NavigationBarBadgeNode(fillColor: theme.badgeBackgroundColor, strokeColor: theme.badgeStrokeColor, textColor: theme.badgeTextColor)
        self.badgeNode.isUserInteractionEnabled = false
        self.badgeNode.isHidden = true
        self.backButtonArrow = ASImageNode()
        self.backButtonArrow.displayWithoutProcessing = true
        self.backButtonArrow.displaysAsynchronously = false
        self.leftButtonNode = NavigationButtonNode()
        self.rightButtonNode = NavigationButtonNode()
        
        self.clippingNode = ASDisplayNode()
        self.clippingNode.clipsToBounds = true
        
        self.backButtonNode.color = self.theme.buttonColor
        self.leftButtonNode.color = self.theme.buttonColor
        self.rightButtonNode.color = self.theme.buttonColor
        self.backButtonArrow.image = backArrowImage(color: self.theme.buttonColor)
        if let title = self.title {
            self.titleNode.attributedText = NSAttributedString(string: title, font: Font.semibold(17.0), textColor: self.theme.primaryTextColor)
        }
        self.stripeNode.backgroundColor = self.theme.separatorColor
        
        super.init()
        
        self.addSubnode(self.clippingNode)
        
        self.backgroundColor = self.theme.backgroundColor
        
        self.stripeNode.isLayerBacked = true
        self.stripeNode.displaysAsynchronously = false
        self.addSubnode(self.stripeNode)
        
        self.titleNode.displaysAsynchronously = false
        self.titleNode.maximumNumberOfLines = 1
        self.titleNode.truncationMode = .byTruncatingTail
        self.titleNode.isOpaque = false
        
        self.backButtonNode.highlightChanged = { [weak self] highlighted in
            if let strongSelf = self {
                strongSelf.backButtonArrow.alpha = (highlighted ? 0.4 : 1.0)
            }
        }
        self.backButtonNode.pressed = { [weak self] in
            if let strongSelf = self {
                if let leftBarButtonItem = strongSelf.item?.leftBarButtonItem, leftBarButtonItem.backButtonAppearance {
                    leftBarButtonItem.performActionOnTarget()
                } else {
                    strongSelf.backPressed()
                }
            }
        }
        
        self.leftButtonNode.pressed = { [weak self] in
            if let item = self?.item, let leftBarButtonItem = item.leftBarButtonItem {
                leftBarButtonItem.performActionOnTarget()
            }
        }
        
        self.rightButtonNode.pressed = { [weak self] in
            if let item = self?.item, let rightBarButtonItem = item.rightBarButtonItem {
                rightBarButtonItem.performActionOnTarget()
            }
        }
    }
    
    public func updateTheme(_ theme: NavigationBarTheme) {
        if theme !== self.theme {
            self.theme = theme
            
            self.backgroundColor = self.theme.backgroundColor
            
            self.backButtonNode.color = self.theme.buttonColor
            self.leftButtonNode.color = self.theme.buttonColor
            self.rightButtonNode.color = self.theme.buttonColor
            self.backButtonArrow.image = backArrowImage(color: self.theme.buttonColor)
            if let title = self.title {
                self.titleNode.attributedText = NSAttributedString(string: title, font: Font.semibold(17.0), textColor: self.theme.primaryTextColor)
            }
            self.stripeNode.backgroundColor = self.theme.separatorColor
            
            self.badgeNode.updateTheme(fillColor: theme.badgeBackgroundColor, strokeColor: theme.badgeStrokeColor, textColor: theme.badgeTextColor)
        }
    }
    
    private func requestLayout() {
        self.requestedLayout = true
        self.setNeedsLayout()
    }
    
    override open func layout() {
        super.layout()
        
        if let validLayout = self.validLayout, self.requestedLayout {
            self.requestedLayout = false
            self.updateLayout(size: validLayout.0, leftInset: validLayout.1, rightInset: validLayout.2, transition: .immediate)
        }
    }
    
    func updateLayout(size: CGSize, leftInset: CGFloat, rightInset: CGFloat, transition: ContainedViewLayoutTransition) {
        self.validLayout = (size, leftInset, rightInset)
        
        let leftButtonInset: CGFloat = leftInset + 16.0
        let backButtonInset: CGFloat = leftInset + 27.0
        
        transition.updateFrame(node: self.clippingNode, frame: CGRect(origin: CGPoint(), size: size))
        if let contentNode = self.contentNode {
            transition.updateFrame(node: contentNode, frame: CGRect(origin: CGPoint(x: leftInset, y: 0.0), size: CGSize(width: size.width - leftInset - rightInset, height: size.height)))
        }
        
        transition.updateFrame(node: self.stripeNode, frame: CGRect(x: 0.0, y: size.height, width: size.width, height: UIScreenPixel))
        
        let nominalHeight: CGFloat = self.collapsed ? 32.0 : 44.0
        let contentVerticalOrigin = size.height - nominalHeight
        
        var leftTitleInset: CGFloat = leftInset + 4.0
        var rightTitleInset: CGFloat = rightInset + 4.0
        if self.backButtonNode.supernode != nil {
            let backButtonSize = self.backButtonNode.measure(CGSize(width: size.width, height: nominalHeight))
            leftTitleInset += backButtonSize.width + backButtonInset + 4.0 + 4.0
            
            let topHitTestSlop = (nominalHeight - backButtonSize.height) * 0.5
            self.backButtonNode.hitTestSlop = UIEdgeInsetsMake(-topHitTestSlop, -27.0, -topHitTestSlop, -8.0)
            
            if let transitionState = self.transitionState {
                let progress = transitionState.progress
                
                switch transitionState.role {
                    case .top:
                        let initialX: CGFloat = backButtonInset
                        let finalX: CGFloat = floor((size.width - backButtonSize.width) / 2.0) - size.width
                        
                        self.backButtonNode.frame = CGRect(origin: CGPoint(x: initialX * (1.0 - progress) + finalX * progress, y: contentVerticalOrigin + floor((nominalHeight - backButtonSize.height) / 2.0)), size: backButtonSize)
                        self.backButtonNode.alpha = (1.0 - progress) * (1.0 - progress)
                    
                        if let transitionTitleNode = self.transitionTitleNode {
                            let transitionTitleSize = transitionTitleNode.measure(CGSize(width: size.width, height: nominalHeight))
                            
                            let initialX: CGFloat = backButtonInset + floor((backButtonSize.width - transitionTitleSize.width) / 2.0)
                            let finalX: CGFloat = floor((size.width - transitionTitleSize.width) / 2.0) - size.width
                            
                            transitionTitleNode.frame = CGRect(origin: CGPoint(x: initialX * (1.0 - progress) + finalX * progress, y: contentVerticalOrigin + floor((nominalHeight - transitionTitleSize.height) / 2.0)), size: transitionTitleSize)
                            transitionTitleNode.alpha = progress * progress
                        }
                    
                        self.backButtonArrow.frame = CGRect(origin: CGPoint(x: leftInset + 8.0 - progress * size.width, y: contentVerticalOrigin + floor((nominalHeight - 22.0) / 2.0)), size: CGSize(width: 13.0, height: 22.0))
                        self.backButtonArrow.alpha = max(0.0, 1.0 - progress * 1.3)
                        self.badgeNode.alpha = max(0.0, 1.0 - progress * 1.3)
                    case .bottom:
                        self.backButtonNode.alpha = 1.0
                        self.backButtonNode.frame = CGRect(origin: CGPoint(x: backButtonInset, y: contentVerticalOrigin + floor((nominalHeight - backButtonSize.height) / 2.0)), size: backButtonSize)
                        self.backButtonArrow.alpha = 1.0
                        self.backButtonArrow.frame = CGRect(origin: CGPoint(x: leftInset + 8.0, y: contentVerticalOrigin + floor((nominalHeight - 22.0) / 2.0)), size: CGSize(width: 13.0, height: 22.0))
                        self.badgeNode.alpha = 1.0
                }
            } else {
                self.backButtonNode.alpha = 1.0
                self.backButtonNode.frame = CGRect(origin: CGPoint(x: backButtonInset, y: contentVerticalOrigin + floor((nominalHeight - backButtonSize.height) / 2.0)), size: backButtonSize)
                self.backButtonArrow.alpha = 1.0
                self.backButtonArrow.frame = CGRect(origin: CGPoint(x: leftInset + 8.0, y: contentVerticalOrigin + floor((nominalHeight - 22.0) / 2.0)), size: CGSize(width: 13.0, height: 22.0))
                self.badgeNode.alpha = 1.0
            }
        } else if self.leftButtonNode.supernode != nil {
            let leftButtonSize = self.leftButtonNode.measure(CGSize(width: size.width, height: nominalHeight))
            leftTitleInset += leftButtonSize.width + leftButtonInset + 8.0 + 8.0
            
            self.leftButtonNode.alpha = 1.0
            self.leftButtonNode.frame = CGRect(origin: CGPoint(x: leftButtonInset, y: contentVerticalOrigin + floor((nominalHeight - leftButtonSize.height) / 2.0)), size: leftButtonSize)
        }
        
        let badgeSize = self.badgeNode.measure(CGSize(width: 200.0, height: 100.0))
        let backButtonArrowFrame = self.backButtonArrow.frame
        self.badgeNode.frame = CGRect(origin: backButtonArrowFrame.origin.offsetBy(dx: 7.0, dy: -9.0), size: badgeSize)
        
        if self.rightButtonNode.supernode != nil {
            let rightButtonSize = self.rightButtonNode.measure(CGSize(width: size.width, height: nominalHeight))
            rightTitleInset += rightButtonSize.width + leftButtonInset + 8.0 + 8.0
            self.rightButtonNode.alpha = 1.0
            self.rightButtonNode.frame = CGRect(origin: CGPoint(x: size.width - leftButtonInset - rightButtonSize.width, y: contentVerticalOrigin + floor((nominalHeight - rightButtonSize.height) / 2.0)), size: rightButtonSize)
        }
        
        if let transitionState = self.transitionState {
            let progress = transitionState.progress
            
            switch transitionState.role {
                case .top:
                    break
                case .bottom:
                    if let transitionBackButtonNode = self.transitionBackButtonNode {
                        let transitionBackButtonSize = transitionBackButtonNode.measure(CGSize(width: size.width, height: nominalHeight))
                        let initialX: CGFloat = backButtonInset + size.width * 0.3
                        let finalX: CGFloat = floor((size.width - transitionBackButtonSize.width) / 2.0)
                        
                        transitionBackButtonNode.frame = CGRect(origin: CGPoint(x: initialX * (1.0 - progress) + finalX * progress, y: contentVerticalOrigin + floor((nominalHeight - transitionBackButtonSize.height) / 2.0)), size: transitionBackButtonSize)
                        transitionBackButtonNode.alpha = (1.0 - progress) * (1.0 - progress)
                    }
                
                    if let transitionBackArrowNode = self.transitionBackArrowNode {
                        let initialX: CGFloat = leftInset + 8.0 + size.width * 0.3
                        let finalX: CGFloat = leftInset + 8.0
                        
                        transitionBackArrowNode.frame = CGRect(origin: CGPoint(x: initialX * (1.0 - progress) + finalX * progress, y: contentVerticalOrigin + floor((nominalHeight - 22.0) / 2.0)), size: CGSize(width: 13.0, height: 22.0))
                        transitionBackArrowNode.alpha = max(0.0, 1.0 - progress * 1.3)
                        
                        if let transitionBadgeNode = self.transitionBadgeNode {
                            transitionBadgeNode.frame = CGRect(origin: transitionBackArrowNode.frame.origin.offsetBy(dx: 7.0, dy: -9.0), size: transitionBadgeNode.bounds.size)
                            transitionBadgeNode.alpha = transitionBackArrowNode.alpha
                        }
                    }
                }
        }
        
        leftTitleInset = floor(leftTitleInset)
        if Int(leftTitleInset) % 2 != 0 {
            leftTitleInset -= 1.0
        }
        
        if self.titleNode.supernode != nil {
            let titleSize = self.titleNode.measure(CGSize(width: max(1.0, size.width - max(leftTitleInset, rightTitleInset) * 2.0), height: nominalHeight))
            
            if let transitionState = self.transitionState, let otherNavigationBar = transitionState.navigationBar {
                let progress = transitionState.progress
                
                switch transitionState.role {
                    case .top:
                        let initialX = floor((size.width - titleSize.width) / 2.0)
                        let finalX: CGFloat = leftButtonInset
                        
                        self.titleNode.frame = CGRect(origin: CGPoint(x: initialX * (1.0 - progress) + finalX * progress, y: contentVerticalOrigin + floorToScreenPixels((nominalHeight - titleSize.height) / 2.0)), size: titleSize)
                        self.titleNode.alpha = (1.0 - progress) * (1.0 - progress)
                    case .bottom:
                        var initialX: CGFloat = backButtonInset
                        if otherNavigationBar.backButtonNode.supernode != nil {
                            initialX += floor((otherNavigationBar.backButtonNode.frame.size.width - titleSize.width) / 2.0)
                        }
                        initialX += size.width * 0.3
                        let finalX: CGFloat = floor((size.width - titleSize.width) / 2.0)
                        
                        self.titleNode.frame = CGRect(origin: CGPoint(x: initialX * (1.0 - progress) + finalX * progress, y: contentVerticalOrigin + floorToScreenPixels((nominalHeight - titleSize.height) / 2.0)), size: titleSize)
                    self.titleNode.alpha = progress * progress
                }
            } else {
                self.titleNode.alpha = 1.0
                self.titleNode.frame = CGRect(origin: CGPoint(x: floor((size.width - titleSize.width) / 2.0), y: contentVerticalOrigin + floorToScreenPixels((nominalHeight - titleSize.height) / 2.0)), size: titleSize)
            }
        }
        
        if let titleView = self.titleView {
            let titleSize = CGSize(width: max(1.0, size.width - max(leftTitleInset, rightTitleInset) * 2.0), height: nominalHeight)
            titleView.frame = CGRect(origin: CGPoint(x: leftTitleInset, y: contentVerticalOrigin), size: titleSize)
            
            if let transitionState = self.transitionState, let otherNavigationBar = transitionState.navigationBar {
                let progress = transitionState.progress
                
                switch transitionState.role {
                    case .top:
                        let initialX = floor((size.width - titleSize.width) / 2.0)
                        let finalX: CGFloat = leftButtonInset
                        
                        titleView.frame = CGRect(origin: CGPoint(x: initialX * (1.0 - progress) + finalX * progress, y: contentVerticalOrigin + floorToScreenPixels((nominalHeight - titleSize.height) / 2.0)), size: titleSize)
                        titleView.alpha = (1.0 - progress) * (1.0 - progress)
                    case .bottom:
                        var initialX: CGFloat = backButtonInset
                        if otherNavigationBar.backButtonNode.supernode != nil {
                            initialX += floor((otherNavigationBar.backButtonNode.frame.size.width - titleSize.width) / 2.0)
                        }
                        initialX += size.width * 0.3
                        let finalX: CGFloat = floor((size.width - titleSize.width) / 2.0)
                        
                        titleView.frame = CGRect(origin: CGPoint(x: initialX * (1.0 - progress) + finalX * progress, y: contentVerticalOrigin + floorToScreenPixels((nominalHeight - titleSize.height) / 2.0)), size: titleSize)
                        titleView.alpha = progress * progress
                }
            } else {
                if self.hintAnimateTitleNodeOnNextLayout {
                    self.hintAnimateTitleNodeOnNextLayout = false
                    if let titleView = titleView as? NavigationBarTitleView {
                        titleView.animateLayoutTransition()
                    }
                }
                titleView.alpha = 1.0
                titleView.frame = CGRect(origin: CGPoint(x: floor((size.width - titleSize.width) / 2.0), y: contentVerticalOrigin + floorToScreenPixels((nominalHeight - titleSize.height) / 2.0)), size: titleSize)
            }
        }
    }
    
    public func makeTransitionTitleNode(foregroundColor: UIColor) -> ASDisplayNode? {
        if let titleView = self.titleView {
            if let transitionView = titleView as? NavigationBarTitleTransitionNode {
                return transitionView.makeTransitionMirrorNode()
            } else {
                return nil
            }
        } else if let title = self.title {
            let node = ASTextNode()
            node.attributedText = NSAttributedString(string: title, font: Font.semibold(17.0), textColor: foregroundColor)
            return node
        } else {
            return nil
        }
    }
    
    private func makeTransitionBackButtonNode(accentColor: UIColor) -> NavigationButtonNode? {
        if self.backButtonNode.supernode != nil {
            let node = NavigationButtonNode()
            node.text = self.backButtonNode.text
            node.color = accentColor
            return node
        } else {
            return nil
        }
    }
    
    private func makeTransitionBackArrowNode(accentColor: UIColor) -> ASDisplayNode? {
        if self.backButtonArrow.supernode != nil {
            let node = ASImageNode()
            node.image = backArrowImage(color: accentColor)
            node.frame = self.backButtonArrow.frame
            node.displayWithoutProcessing = true
            node.displaysAsynchronously = false
            return node
        } else {
            return nil
        }
    }
    
    private func makeTransitionBadgeNode() -> ASDisplayNode? {
        if self.badgeNode.supernode != nil && !self.badgeNode.isHidden {
            let node = NavigationBarBadgeNode(fillColor: self.theme.badgeBackgroundColor, strokeColor: self.theme.badgeStrokeColor, textColor: self.theme.badgeTextColor)
            node.text = self.badgeNode.text
            let nodeSize = node.measure(CGSize(width: 200.0, height: 100.0))
            node.frame = CGRect(origin: CGPoint(), size: nodeSize)
            return node
        } else {
            return nil
        }
    }
    
    public func setContentNode(_ contentNode: NavigationBarContentNode?, animated: Bool) {
        if self.contentNode !== contentNode {
            if let previous = self.contentNode {
                if animated {
                    previous.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false, completion: { [weak self, weak previous] _ in
                        if let strongSelf = self, let previous = previous {
                            if previous !== strongSelf.contentNode {
                                previous.removeFromSupernode()
                            }
                        }
                    })
                } else {
                    previous.removeFromSupernode()
                }
            }
            self.contentNode = contentNode
            if let contentNode = contentNode {
                contentNode.layer.removeAnimation(forKey: "opacity")
                self.addSubnode(contentNode)
                if animated {
                    contentNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
                }
                
                if !self.clippingNode.alpha.isZero {
                    self.clippingNode.alpha = 0.0
                    if animated {
                        self.clippingNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2)
                    }
                }
                
                if !self.bounds.size.width.isZero {
                    self.requestedLayout = true
                    self.layout()
                } else {
                    self.requestLayout()
                }
            } else if self.clippingNode.alpha.isZero {
                self.clippingNode.alpha = 1.0
                if animated {
                    self.clippingNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
                }
            }
        }
    }
}
