import Foundation
import UIKit
import AsyncDisplayKit
import Display

struct NetworkStatusTitle: Equatable {
    let text: String
    let activity: Bool
    let hasProxy: Bool
    let connectsViaProxy: Bool
}

final class NetworkStatusTitleView: UIView, NavigationBarTitleView, NavigationBarTitleTransitionNode {
    private let titleNode: ImmediateTextNode
    private let lockView: ChatListTitleLockView
    private let activityIndicator: ActivityIndicator
    private let buttonView: HighlightTrackingButton
    private let proxyNode: ChatTitleProxyNode
    private let proxyButton: HighlightTrackingButton
    
    private var validLayout: (CGSize, CGRect)?
    
    var title: NetworkStatusTitle = NetworkStatusTitle(text: "", activity: false, hasProxy: false, connectsViaProxy: false) {
        didSet {
            if self.title != oldValue {
                self.titleNode.attributedText = NSAttributedString(string: title.text, font: Font.bold(17.0), textColor: self.theme.rootController.navigationBar.primaryTextColor)
                self.activityIndicator.isHidden = !self.title.activity
                if self.title.connectsViaProxy {
                    self.proxyNode.status = self.title.activity ? .connecting : .connected
                } else {
                    self.proxyNode.status = .available
                }
                self.proxyNode.isHidden = !self.title.hasProxy
                self.proxyButton.isHidden = !self.title.hasProxy

                self.setNeedsLayout()
            }
        }
    }
    
    var toggleIsLocked: (() -> Void)?
    var openProxySettings: (() -> Void)?
    
    private var isPasscodeSet = false
    private var isManuallyLocked = false
    
    var theme: PresentationTheme {
        didSet {
            self.titleNode.attributedText = NSAttributedString(string: self.title.text, font: Font.medium(17.0), textColor: self.theme.rootController.navigationBar.primaryTextColor)
            
            if self.isPasscodeSet {
                self.lockView.setIsLocked(self.isManuallyLocked, theme: self.theme, animated: false)
            } else {
                self.lockView.setIsLocked(false, theme: self.theme, animated: false)
            }
            
            self.activityIndicator.type = .custom(self.theme.rootController.navigationBar.primaryTextColor, 22.0, 1.5)
            self.proxyNode.theme = self.theme
        }
    }
    
    init(theme: PresentationTheme) {
        self.theme = theme
        
        self.titleNode = ImmediateTextNode()
        self.titleNode.displaysAsynchronously = false
        self.titleNode.maximumNumberOfLines = 1
        self.titleNode.truncationType = .end
        self.titleNode.isOpaque = false
        self.titleNode.isUserInteractionEnabled = false
        
        self.activityIndicator = ActivityIndicator(type: .custom(theme.rootController.navigationBar.primaryTextColor, 22.0, 1.5), speed: .slow)
        let activityIndicatorSize = self.activityIndicator.measure(CGSize(width: 100.0, height: 100.0))
        self.activityIndicator.frame = CGRect(origin: CGPoint(), size: activityIndicatorSize)
        
        self.lockView = ChatListTitleLockView(frame: CGRect(origin: CGPoint(), size: CGSize(width: 2.0, height: 2.0)))
        self.lockView.isHidden = true
        self.lockView.isUserInteractionEnabled = false
        
        self.proxyNode = ChatTitleProxyNode(theme: self.theme)
        self.proxyNode.isHidden = true
        
        self.buttonView = HighlightTrackingButton()
        self.proxyButton = HighlightTrackingButton()
        self.proxyButton.isHidden = true
        
        super.init(frame: CGRect())
        
        self.addSubnode(self.activityIndicator)
        self.addSubnode(self.titleNode)
        self.addSubnode(self.proxyNode)
        self.addSubview(self.lockView)
        self.addSubview(self.buttonView)
        self.addSubview(self.proxyButton)
        
        self.buttonView.highligthedChanged = { [weak self] highlighted in
            if let strongSelf = self {
                if highlighted && !strongSelf.lockView.isHidden && strongSelf.activityIndicator.isHidden {
                    strongSelf.titleNode.layer.removeAnimation(forKey: "opacity")
                    strongSelf.lockView.layer.removeAnimation(forKey: "opacity")
                    strongSelf.titleNode.alpha = 0.4
                    strongSelf.lockView.alpha = 0.4
                } else {
                    if !strongSelf.titleNode.alpha.isEqual(to: 1.0) {
                        strongSelf.titleNode.alpha = 1.0
                        strongSelf.titleNode.layer.animateAlpha(from: 0.4, to: 1.0, duration: 0.2)
                    }
                    if !strongSelf.lockView.alpha.isEqual(to: 1.0) {
                        strongSelf.lockView.alpha = 1.0
                        strongSelf.lockView.layer.animateAlpha(from: 0.4, to: 1.0, duration: 0.2)
                    }
                }
            }
        }
        
        self.buttonView.addTarget(self, action: #selector(self.buttonPressed), for: .touchUpInside)
        
        self.proxyButton.highligthedChanged = { [weak self] highlighted in
            if let strongSelf = self {
                if highlighted {
                    strongSelf.proxyNode.layer.removeAnimation(forKey: "opacity")
                    strongSelf.proxyNode.alpha = 0.4
                } else {
                    if !strongSelf.proxyNode.alpha.isEqual(to: 1.0) {
                        strongSelf.proxyNode.alpha = 1.0
                        strongSelf.proxyNode.layer.animateAlpha(from: 0.4, to: 1.0, duration: 0.2)
                    }
                }
            }
        }
        
        self.proxyButton.addTarget(self, action: #selector(self.proxyButtonPressed), for: .touchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let (size, clearBounds) = self.validLayout {
            self.updateLayout(size: size, clearBounds: clearBounds, transition: .immediate)
        }
    }
    
    func updateLayout(size: CGSize, clearBounds: CGRect, transition: ContainedViewLayoutTransition) {
        self.validLayout = (size, clearBounds)
        
        var indicatorPadding: CGFloat = 0.0
        let indicatorSize = self.activityIndicator.bounds.size
        
        if !self.activityIndicator.isHidden {
            indicatorPadding = indicatorSize.width + 6.0
        }
        var maxTitleWidth = clearBounds.size.width - indicatorPadding
        var alignedTitleWidth = size.width - indicatorPadding
        var proxyPadding: CGFloat = 0.0
        if !self.proxyNode.isHidden {
            maxTitleWidth -= 25.0
            alignedTitleWidth -= 20.0
            proxyPadding += 39.0
        }
        
        let titleSize = self.titleNode.updateLayout(CGSize(width: max(1.0, maxTitleWidth), height: size.height))
        
        let combinedHeight = titleSize.height
        
        var titleContentRect = CGRect(origin: CGPoint(x: indicatorPadding + floor((size.width - titleSize.width - indicatorPadding) / 2.0), y: floor((size.height - combinedHeight) / 2.0)), size: titleSize)
        titleContentRect.origin.x = min(titleContentRect.origin.x, clearBounds.maxX - proxyPadding - titleContentRect.width)
        
        let titleFrame = titleContentRect
        self.titleNode.frame = titleFrame
        
        let proxyFrame = CGRect(origin: CGPoint(x: clearBounds.maxX - 16.0 - self.proxyNode.bounds.width, y: 1.0 + floor((size.height - proxyNode.bounds.height) / 2.0)), size: proxyNode.bounds.size)
        self.proxyNode.frame = proxyFrame
        self.proxyButton.frame = proxyFrame.insetBy(dx: -2.0, dy: -2.0)
        
        let buttonX = max(0.0, titleFrame.minX - 10.0)
        self.buttonView.frame = CGRect(origin: CGPoint(x: buttonX, y: 0.0), size: CGSize(width: min(titleFrame.maxX + 28.0, size.width) - buttonX, height: titleFrame.maxY))
        
        self.lockView.frame = CGRect(x: titleFrame.maxX + 6.0, y: titleFrame.minY + 4.0, width: 2.0, height: 2.0)
        
        self.activityIndicator.frame = CGRect(origin: CGPoint(x: titleFrame.minX - indicatorSize.width - 6.0, y: titleFrame.minY - 1.0), size: indicatorSize)
    }
    
    func updatePasscode(isPasscodeSet: Bool, isManuallyLocked: Bool) {
        if self.isPasscodeSet == isPasscodeSet && self.isManuallyLocked == isManuallyLocked {
            return
        }
        
        self.isPasscodeSet = isPasscodeSet
        self.isManuallyLocked = isManuallyLocked
        
        if isPasscodeSet {
            self.buttonView.isHidden = false
            self.lockView.isHidden = false
            self.lockView.setIsLocked(isManuallyLocked, theme: self.theme, animated: !self.bounds.size.width.isZero)
        } else {
            self.buttonView.isHidden = true
            self.lockView.isHidden = true
            self.lockView.setIsLocked(false, theme: self.theme, animated: false)
        }
    }
    
    @objc private func buttonPressed() {
        self.toggleIsLocked?()
    }
    
    @objc private func proxyButtonPressed() {
        self.openProxySettings?()
    }
    
    func makeTransitionMirrorNode() -> ASDisplayNode {
        let view = NetworkStatusTitleView(theme: self.theme)
        view.title = self.title
        
        return ASDisplayNode(viewBlock: {
            return view
        }, didLoad: nil)
    }
    
    func animateLayoutTransition() {
    }
    
    func proxyButtonRect() -> CGRect? {
        if !self.proxyNode.isHidden {
            return proxyNode.frame
        }
        return nil
    }
}
