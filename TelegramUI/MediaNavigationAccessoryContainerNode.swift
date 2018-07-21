import Foundation
import AsyncDisplayKit
import Display
import TelegramCore

final class MediaNavigationAccessoryContainerNode: ASDisplayNode, UIGestureRecognizerDelegate {
    let backgroundNode: ASDisplayNode
    let headerNode: MediaNavigationAccessoryHeaderNode
    
    private let currentHeaderHeight: CGFloat = MediaNavigationAccessoryHeaderNode.minimizedHeight
    
    private var presentationData: PresentationData
    
    init(account: Account) {
        self.presentationData = account.telegramApplicationContext.currentPresentationData.with { $0 }
        
        self.backgroundNode = ASDisplayNode()
        self.headerNode = MediaNavigationAccessoryHeaderNode(theme: self.presentationData.theme, strings: self.presentationData.strings)
        
        super.init()
        
        self.backgroundNode.backgroundColor = self.presentationData.theme.rootController.navigationBar.backgroundColor
        self.addSubnode(self.backgroundNode)
        
        self.addSubnode(self.headerNode)
        
        self.headerNode.tapAction = { [weak self] in
            if let strongSelf = self {
                
            }
        }
    }
    
    func updatePresentationData(_ presentationData: PresentationData) {
        self.presentationData = presentationData
        
        self.backgroundNode.backgroundColor = self.presentationData.theme.rootController.navigationBar.backgroundColor
        self.headerNode.updatePresentationData(presentationData)
    }
    
    func updateLayout(size: CGSize, transition: ContainedViewLayoutTransition) {
        transition.updateFrame(node: self.backgroundNode, frame: CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: CGSize(width: size.width, height: self.currentHeaderHeight)))
        
        let headerHeight = self.currentHeaderHeight
        transition.updateFrame(node: self.headerNode, frame: CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: CGSize(width: size.width, height: headerHeight)))
        self.headerNode.updateLayout(size: CGSize(width: size.width, height: headerHeight), transition: transition)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if !self.headerNode.frame.contains(point) {
            return nil
        }
        return super.hitTest(point, with: event)
    }
}
