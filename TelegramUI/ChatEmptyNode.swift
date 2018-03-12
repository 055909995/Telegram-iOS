import Foundation
import AsyncDisplayKit
import Display
import Postbox
import TelegramCore

private protocol ChatEmptyNodeContent {
    func updateLayout(interfaceState: ChatPresentationInterfaceState, size: CGSize, transition: ContainedViewLayoutTransition) -> CGSize
}

private let titleFont = Font.medium(15.0)
private let messageFont = Font.regular(14.0)

private final class ChatEmptyNodeRegularChatContent: ASDisplayNode, ChatEmptyNodeContent {
    private let iconNode: ASImageNode
    private let textNode: ImmediateTextNode
    
    private var currentTheme: PresentationTheme?
    private var currentStrings: PresentationStrings?
    
    override init() {
        self.iconNode = ASImageNode()
        self.textNode = ImmediateTextNode()
        
        super.init()
        
        self.addSubnode(self.iconNode)
        self.addSubnode(self.textNode)
    }
    
    func updateLayout(interfaceState: ChatPresentationInterfaceState, size: CGSize, transition: ContainedViewLayoutTransition) -> CGSize {
        if self.currentTheme !== interfaceState.theme || self.currentStrings !== interfaceState.strings {
            self.currentTheme = interfaceState.theme
            self.currentStrings = interfaceState.strings
            
            self.iconNode.image = PresentationResourcesChat.chatEmptyItemIconImage(interfaceState.theme)
            self.textNode.attributedText = NSAttributedString(string: interfaceState.strings.Conversation_EmptyPlaceholder, font: messageFont, textColor: interfaceState.theme.chat.serviceMessage.serviceMessagePrimaryTextColor)
        }
        
        let insets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
        
        let iconSize = self.iconNode.image?.size ?? CGSize()
        let textSize = self.textNode.updateLayout(CGSize(width: size.width - insets.left - insets.right, height: CGFloat.greatestFiniteMagnitude))
        let spacing: CGFloat = 8.0
        
        let contentWidth = max(iconSize.width, textSize.width)
        let contentHeight = iconSize.height + spacing + textSize.height
        let contentRect = CGRect(origin: CGPoint(x: insets.left, y: insets.top), size: CGSize(width: contentWidth, height: contentHeight))
        
        let iconFrame = CGRect(origin: CGPoint(x: contentRect.minX + floor((contentRect.width - iconSize.width) / 2.0), y: contentRect.minY), size: iconSize)
        transition.updateFrame(node: self.iconNode, frame: iconFrame)
        transition.updateFrame(node: self.textNode, frame: CGRect(origin: CGPoint(x: contentRect.minX + floor((contentRect.width - textSize.width) / 2.0), y: iconFrame.maxY + spacing), size: textSize))
        
        return contentRect.insetBy(dx: -insets.left, dy: -insets.top).size
    }
}

private final class ChatEmptyNodeSecretChatContent: ASDisplayNode, ChatEmptyNodeContent {
    private let titleNode: ImmediateTextNode
    private let subtitleNode: ImmediateTextNode
    private var lineNodes: [(ASImageNode, ImmediateTextNode)] = []
    
    private var currentTheme: PresentationTheme?
    private var currentStrings: PresentationStrings?
    
    override init() {
        self.titleNode = ImmediateTextNode()
        self.titleNode.maximumNumberOfLines = 0
        self.titleNode.lineSpacing = 0.15
        self.titleNode.textAlignment = .center
        self.titleNode.isLayerBacked = true
        self.titleNode.displaysAsynchronously = false
        
        self.subtitleNode = ImmediateTextNode()
        self.subtitleNode.maximumNumberOfLines = 0
        self.subtitleNode.isLayerBacked = true
        self.subtitleNode.displaysAsynchronously = false
        
        super.init()
        
        self.addSubnode(self.titleNode)
        self.addSubnode(self.subtitleNode)
    }
    
    func updateLayout(interfaceState: ChatPresentationInterfaceState, size: CGSize, transition: ContainedViewLayoutTransition) -> CGSize {
        if self.currentTheme !== interfaceState.theme || self.currentStrings !== interfaceState.strings {
            self.currentTheme = interfaceState.theme
            self.currentStrings = interfaceState.strings
            
            var title = " "
            var incoming = false
            if let renderedPeer = interfaceState.renderedPeer {
                if let chatPeer = renderedPeer.peers[renderedPeer.peerId] as? TelegramSecretChat {
                    if case .participant = chatPeer.role {
                        incoming = true
                    }
                    if let user = renderedPeer.peers[chatPeer.regularPeerId] {
                        title = user.compactDisplayTitle
                    }
                }
            }
            
            let titleString: String
            if incoming {
                titleString = interfaceState.strings.Conversation_EncryptedPlaceholderTitleIncoming(title).0
            } else {
                titleString = interfaceState.strings.Conversation_EncryptedPlaceholderTitleOutgoing(title).0
            }
            
            self.titleNode.attributedText = NSAttributedString(string: titleString, font: titleFont, textColor: interfaceState.theme.chat.serviceMessage.serviceMessagePrimaryTextColor)
            
            self.subtitleNode.attributedText = NSAttributedString(string: interfaceState.strings.Conversation_EncryptedDescriptionTitle, font: messageFont, textColor: interfaceState.theme.chat.serviceMessage.serviceMessagePrimaryTextColor)
            
            let strings: [String] = [
                interfaceState.strings.Conversation_EncryptedDescription1,
                interfaceState.strings.Conversation_EncryptedDescription2,
                interfaceState.strings.Conversation_EncryptedDescription3,
                interfaceState.strings.Conversation_EncryptedDescription4
            ]
            
            let lines: [NSAttributedString] = strings.map { NSAttributedString(string: $0, font: messageFont, textColor: interfaceState.theme.chat.serviceMessage.serviceMessagePrimaryTextColor) }
            
            let lockIcon = PresentationResourcesChat.chatEmptyItemLockIcon(interfaceState.theme)
            
            for i in 0 ..< lines.count {
                if i >= self.lineNodes.count {
                    let iconNode = ASImageNode()
                    iconNode.isLayerBacked = true
                    iconNode.displaysAsynchronously = false
                    iconNode.displayWithoutProcessing = true
                    let textNode = ImmediateTextNode()
                    textNode.maximumNumberOfLines = 0
                    textNode.isLayerBacked = true
                    textNode.displaysAsynchronously = false
                    self.addSubnode(iconNode)
                    self.addSubnode(textNode)
                    self.lineNodes.append((iconNode, textNode))
                }
                
                self.lineNodes[i].0.image = lockIcon
                self.lineNodes[i].1.attributedText = lines[i]
            }
        }
        
        let insets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
        let titleSpacing: CGFloat = 4.0
        let subtitleSpacing: CGFloat = 3.0
        let iconInset: CGFloat = 14.0
        
        var contentWidth: CGFloat = 100.0
        var contentHeight: CGFloat = 0.0
        
        var lineNodes: [(CGSize, ASImageNode, ImmediateTextNode)] = []
        for (iconNode, textNode) in self.lineNodes {
            let textSize = textNode.updateLayout(CGSize(width: size.width - insets.left - insets.right - 10.0, height: CGFloat.greatestFiniteMagnitude))
            contentWidth = max(contentWidth, iconInset + textSize.width)
            contentHeight += textSize.height + subtitleSpacing
            lineNodes.append((textSize, iconNode, textNode))
        }
        
        let titleSize = self.titleNode.updateLayout(CGSize(width: contentWidth, height: CGFloat.greatestFiniteMagnitude))
        let subtitleSize = self.subtitleNode.updateLayout(CGSize(width: contentWidth, height: CGFloat.greatestFiniteMagnitude))
        
        contentWidth = max(contentWidth, max(titleSize.width, subtitleSize.width))
        
        contentHeight += titleSize.height + titleSpacing + subtitleSize.height
        
        let contentRect = CGRect(origin: CGPoint(x: insets.left, y: insets.top), size: CGSize(width: contentWidth, height: contentHeight))
        
        let titleFrame = CGRect(origin: CGPoint(x: contentRect.minX + floor((contentRect.width - titleSize.width) / 2.0), y: contentRect.minY), size: titleSize)
        transition.updateFrame(node: self.titleNode, frame: titleFrame)
        let subtitleFrame = CGRect(origin: CGPoint(x: contentRect.minX, y: titleFrame.maxY + titleSpacing), size: subtitleSize)
        transition.updateFrame(node: self.subtitleNode, frame: subtitleFrame)
        
        var lineOffset = subtitleFrame.maxY + subtitleSpacing
        for (textSize, iconNode, textNode) in lineNodes {
            if let image = iconNode.image {
                transition.updateFrame(node: iconNode, frame: CGRect(origin: CGPoint(x: contentRect.minX, y: lineOffset + 1.0), size: image.size))
            }
            transition.updateFrame(node: textNode, frame: CGRect(origin: CGPoint(x: contentRect.minX + iconInset, y: lineOffset), size: textSize))
            lineOffset += textSize.height + subtitleSpacing
        }
        
        return contentRect.insetBy(dx: -insets.left, dy: -insets.top).size
    }
}

private enum ChatEmptyNodeContentType {
    case regular
    case secret
}

final class ChatEmptyNode: ASDisplayNode {
    private let backgroundNode: ASImageNode
    
    private var currentTheme: PresentationTheme?
    private var currentStrings: PresentationStrings?
    
    private var content: (ChatEmptyNodeContentType, ASDisplayNode & ChatEmptyNodeContent)?
    
    override init() {
        self.backgroundNode = ASImageNode()
        self.backgroundNode.isLayerBacked = true
        self.backgroundNode.displayWithoutProcessing = true
        self.backgroundNode.displaysAsynchronously = false
        
        super.init()
        
        self.isUserInteractionEnabled = false
        
        self.addSubnode(self.backgroundNode)
    }
    
    func updateLayout(interfaceState: ChatPresentationInterfaceState, size: CGSize, insets: UIEdgeInsets, transition: ContainedViewLayoutTransition) {
        if self.currentTheme !== interfaceState.theme || self.currentStrings !== interfaceState.strings {
            self.currentTheme = interfaceState.theme
            self.currentStrings = interfaceState.strings
            
            self.backgroundNode.image = PresentationResourcesChat.chatEmptyItemBackgroundImage(interfaceState.theme)
        }
        
        let contentType: ChatEmptyNodeContentType
        if let peer = interfaceState.renderedPeer?.peer {
            if let _ = peer as? TelegramSecretChat {
                contentType = .secret
            } else {
                contentType = .regular
            }
        } else {
            contentType = .regular
        }
        
        var contentTransition = transition
        if self.content?.0 != contentType {
            if let node = self.content?.1 {
                node.removeFromSupernode()
            }
            let node: ASDisplayNode & ChatEmptyNodeContent
            switch contentType {
                case .regular:
                    node = ChatEmptyNodeRegularChatContent()
                case .secret:
                    node = ChatEmptyNodeSecretChatContent()
            }
            self.content = (contentType, node)
            self.addSubnode(node)
            contentTransition = .immediate
        }
        
        let displayRect = CGRect(origin: CGPoint(x: 0.0, y: insets.top), size: CGSize(width: size.width, height: size.height - insets.top - insets.bottom))
        
        var contentSize = CGSize()
        if let contentNode = self.content?.1 {
            contentSize = contentNode.updateLayout(interfaceState: interfaceState, size: displayRect.size, transition: contentTransition)
        }
        
        let contentFrame = CGRect(origin: CGPoint(x: displayRect.minX + floor((displayRect.width - contentSize.width) / 2.0), y: displayRect.minY + floor((displayRect.height - contentSize.height) / 2.0)), size: contentSize)
        if let contentNode = self.content?.1 {
            contentTransition.updateFrame(node: contentNode, frame: contentFrame)
        }
        
        transition.updateFrame(node: self.backgroundNode, frame: contentFrame)
    }
}


