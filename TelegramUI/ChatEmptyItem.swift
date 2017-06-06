import Foundation
import Display
import AsyncDisplayKit
import SwiftSignalKit
import Postbox
import TelegramCore

private let messageFont = Font.medium(14.0)

final class ChatEmptyItem: ListViewItem {
    fileprivate let theme: PresentationTheme
    fileprivate let strings: PresentationStrings
    
    init(theme: PresentationTheme, strings: PresentationStrings) {
        self.theme = theme
        self.strings = strings
    }
    
    func nodeConfiguredForWidth(async: @escaping (@escaping () -> Void) -> Void, width: CGFloat, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, () -> Void)) -> Void) {
        let configure = {
            let node = ChatEmptyItemNode()
            
            let nodeLayout = node.asyncLayout()
            let (layout, apply) = nodeLayout(self, width)
            
            node.contentSize = layout.contentSize
            node.insets = layout.insets
            
            completion(node, {
                return (nil, { apply(.None) })
            })
        }
        if Thread.isMainThread {
            async {
                configure()
            }
        } else {
            configure()
        }
    }
    
    func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: ListViewItemNode, width: CGFloat, previousItem: ListViewItem?, nextItem: ListViewItem?, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping () -> Void) -> Void) {
        if let node = node as? ChatEmptyItemNode {
            Queue.mainQueue().async {
                let nodeLayout = node.asyncLayout()
                
                async {
                    let (layout, apply) = nodeLayout(self, width)
                    Queue.mainQueue().async {
                        completion(layout, {
                            apply(animation)
                        })
                    }
                }
            }
        }
    }
}

final class ChatEmptyItemNode: ListViewItemNode {
    var controllerInteraction: ChatControllerInteraction?
    
    let offsetContainer: ASDisplayNode
    let backgroundNode: ASImageNode
    let iconNode: ASImageNode
    let textNode: TextNode
    
    private var theme: PresentationTheme?
    
    init() {
        self.offsetContainer = ASDisplayNode()
        
        self.backgroundNode = ASImageNode()
        self.backgroundNode.displaysAsynchronously = false
        self.backgroundNode.displayWithoutProcessing = true
        self.iconNode = ASImageNode()
        self.textNode = TextNode()
        
        super.init(layerBacked: false, dynamicBounce: true, rotated: true)
        
        self.transform = CATransform3DMakeRotation(CGFloat.pi, 0.0, 0.0, 1.0)
        
        self.addSubnode(self.offsetContainer)
        self.offsetContainer.addSubnode(self.backgroundNode)
        self.offsetContainer.addSubnode(self.iconNode)
        self.offsetContainer.addSubnode(self.textNode)
        self.wantsTrailingItemSpaceUpdates = true
    }
    
    func asyncLayout() -> (_ item: ChatEmptyItem, _ width: CGFloat) -> (ListViewItemNodeLayout, (ListViewItemUpdateAnimation) -> Void) {
        let makeTextLayout = TextNode.asyncLayout(self.textNode)
        let currentTheme = self.theme
        return { [weak self] item, width in
            var updatedBackgroundImage: UIImage?
            var updatedIconImage: UIImage?
            
            let iconImage = PresentationResourcesChat.chatEmptyItemIconImage(item.theme)
            
            if currentTheme !== item.theme {
                updatedBackgroundImage = PresentationResourcesChat.chatEmptyItemBackgroundImage(item.theme)
                updatedIconImage = iconImage
            }
            
            let attributedText = NSAttributedString(string: item.strings.Conversation_EmptyPlaceholder, font: messageFont, textColor: item.theme.chat.serviceMessage.serviceMessagePrimaryTextColor, paragraphAlignment: .center)
                
            let horizontalEdgeInset: CGFloat = 10.0
            let horizontalContentInset: CGFloat = 12.0
            let verticalItemInset: CGFloat = 10.0
            let verticalContentInset: CGFloat = 14.0
            
            var imageSize = CGSize(width: 80.0, height: 80.0)
            if let iconImage = iconImage {
                imageSize = iconImage.size
            }
            let imageSpacing: CGFloat = 10.0
            
            let (textLayout, textApply) = makeTextLayout(attributedText, nil, 0, .end, CGSize(width: width - horizontalEdgeInset * 2.0 - horizontalContentInset * 2.0, height: CGFloat.greatestFiniteMagnitude), .center, nil, UIEdgeInsets())
            
            let contentWidth = max(textLayout.size.width, 120.0)
            
            let backgroundFrame = CGRect(origin: CGPoint(x: floor((width - contentWidth - horizontalContentInset * 2.0) / 2.0), y: verticalItemInset + 4.0), size: CGSize(width: contentWidth + horizontalContentInset * 2.0, height: textLayout.size.height + imageSize.height + imageSpacing + verticalContentInset * 2.0))
            let textFrame = CGRect(origin: CGPoint(x: backgroundFrame.origin.x + horizontalContentInset + floor((contentWidth - textLayout.size.width) / 2.0), y: backgroundFrame.origin.y + verticalContentInset + imageSize.height + imageSpacing), size: textLayout.size)
            let iconFrame = CGRect(origin: CGPoint(x: backgroundFrame.origin.x + horizontalContentInset + floor((contentWidth - imageSize.width) / 2.0), y: backgroundFrame.origin.y + verticalContentInset), size: imageSize)
            
            let itemLayout = ListViewItemNodeLayout(contentSize: CGSize(width: width, height: imageSize.height + imageSpacing + textLayout.size.height + verticalItemInset * 2.0 + verticalContentInset * 2.0 + 4.0), insets: UIEdgeInsets())
            return (itemLayout, { _ in
                if let strongSelf = self {
                    strongSelf.theme = item.theme
                    
                    if let updatedBackgroundImage = updatedBackgroundImage {
                        strongSelf.backgroundNode.image = updatedBackgroundImage
                    }
                    
                    if let updatedIconImage = updatedIconImage {
                        strongSelf.iconNode.image = updatedIconImage
                    }
                    
                    let _ = textApply()
                    strongSelf.offsetContainer.frame = CGRect(origin: CGPoint(), size: itemLayout.contentSize)
                    strongSelf.backgroundNode.frame = backgroundFrame
                    strongSelf.textNode.frame = textFrame
                    strongSelf.iconNode.frame = iconFrame
                }
            })
        }
    }
    
    override func updateTrailingItemSpace(_ height: CGFloat, transition: ContainedViewLayoutTransition) {
        if height.isLessThanOrEqualTo(0.0) {
            transition.updateBounds(node: self.offsetContainer, bounds: CGRect(origin: CGPoint(), size: self.offsetContainer.bounds.size))
        } else {
            transition.updateBounds(node: self.offsetContainer, bounds: CGRect(origin: CGPoint(x: 0.0, y: floor(height) / 2.0), size: self.offsetContainer.bounds.size))
        }
    }
    
    override func animateAdded(_ currentTimestamp: Double, duration: Double) {
        self.layer.animateAlpha(from: 0.0, to: 1.0, duration: duration * 0.5)
    }
    
    override func animateInsertion(_ currentTimestamp: Double, duration: Double, short: Bool) {
        self.layer.animateAlpha(from: 0.0, to: 1.0, duration: duration * 0.5)
    }
    
    override func animateRemoved(_ currentTimestamp: Double, duration: Double) {
        self.layer.animateAlpha(from: 1.0, to: 0.0, duration: duration * 0.5, removeOnCompletion: false)
    }
}
