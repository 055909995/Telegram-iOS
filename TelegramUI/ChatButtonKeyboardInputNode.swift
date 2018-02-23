import Foundation
import Display
import AsyncDisplayKit
import Postbox
import TelegramCore
import SwiftSignalKit

private final class ChatButtonKeyboardInputButtonNode: ASButtonNode {
    var button: ReplyMarkupButton?
    
    private var theme: PresentationTheme?
    
    init(theme: PresentationTheme) {
        super.init()
        
        self.updateTheme(theme: theme)
    }
    
    func updateTheme(theme: PresentationTheme) {
        if theme !== self.theme {
            self.theme = theme
            
            self.setBackgroundImage(PresentationResourcesChat.chatInputButtonPanelButtonImage(theme), for: [])
            self.setBackgroundImage(PresentationResourcesChat.chatInputButtonPanelButtonHighlightedImage(theme), for: [.highlighted])
        }
    }
}

final class ChatButtonKeyboardInputNode: ChatInputNode {
    private let account: Account
    private let controllerInteraction: ChatControllerInteraction
    
    private let separatorNode: ASDisplayNode
    private let scrollNode: ASScrollNode
    
    private var buttonNodes: [ChatButtonKeyboardInputButtonNode] = []
    private var message: Message?
    
    private var theme: PresentationTheme?
    
    init(account: Account, controllerInteraction: ChatControllerInteraction) {
        self.account = account
        self.controllerInteraction = controllerInteraction
        
        self.scrollNode = ASScrollNode()
        
        self.separatorNode = ASDisplayNode()
        self.separatorNode.isLayerBacked = true
        
        super.init()
        
        self.addSubnode(self.scrollNode)
        self.scrollNode.view.delaysContentTouches = false
        self.scrollNode.view.canCancelContentTouches = true
        
        self.addSubnode(self.separatorNode)
    }
    
    override func didLoad() {
        super.didLoad()
        
        if #available(iOSApplicationExtension 11.0, *) {
            self.scrollNode.view.contentInsetAdjustmentBehavior = .never
        }
    }
    
    override func updateLayout(width: CGFloat, leftInset: CGFloat, rightInset: CGFloat, bottomInset: CGFloat, standardInputHeight: CGFloat, transition: ContainedViewLayoutTransition, interfaceState: ChatPresentationInterfaceState) -> CGFloat {
        transition.updateFrame(node: self.separatorNode, frame: CGRect(origin: CGPoint(), size: CGSize(width: width, height: UIScreenPixel)))
        
        if self.theme !== interfaceState.theme {
            self.theme = interfaceState.theme
            
            self.separatorNode.backgroundColor = interfaceState.theme.chat.inputButtonPanel.panelSerapatorColor
            self.backgroundColor = interfaceState.theme.chat.inputButtonPanel.panelBackgroundColor
        }
        
        var validatedMarkup: ReplyMarkupMessageAttribute?
        if let message = interfaceState.keyboardButtonsMessage {
            for attribute in message.attributes {
                if let replyMarkup = attribute as? ReplyMarkupMessageAttribute {
                    if !replyMarkup.rows.isEmpty {
                        validatedMarkup = replyMarkup
                    }
                    break
                }
            }
        }
        
        self.message = interfaceState.keyboardButtonsMessage
        
        if let markup = validatedMarkup {
            let verticalInset: CGFloat = 10.0
            let sideInset: CGFloat = 6.0 + leftInset
            var buttonHeight: CGFloat = 43.0
            let columnSpacing: CGFloat = 6.0
            let rowSpacing: CGFloat = 5.0
            
            var panelHeight = standardInputHeight
            
            let rowsHeight = verticalInset + CGFloat(markup.rows.count) * buttonHeight + CGFloat(max(0, markup.rows.count - 1)) * rowSpacing + verticalInset
            if !markup.flags.contains(.fit) && rowsHeight < panelHeight {
                buttonHeight = floor((panelHeight - verticalInset * 2.0 - CGFloat(max(0, markup.rows.count - 1)) * rowSpacing) / CGFloat(markup.rows.count))
            }
            
            var verticalOffset = verticalInset
            var buttonIndex = 0
            for row in markup.rows {
                let buttonWidth = floor(((width - sideInset - sideInset) + columnSpacing - CGFloat(row.buttons.count) * columnSpacing) / CGFloat(row.buttons.count))
                
                var columnIndex = 0
                for button in row.buttons {
                    let buttonNode: ChatButtonKeyboardInputButtonNode
                    if buttonIndex < self.buttonNodes.count {
                        buttonNode = self.buttonNodes[buttonIndex]
                        buttonNode.updateTheme(theme: interfaceState.theme)
                    } else {
                        buttonNode = ChatButtonKeyboardInputButtonNode(theme: interfaceState.theme)
                        buttonNode.addTarget(self, action: #selector(self.buttonPressed(_:)), forControlEvents: [.touchUpInside])
                        self.scrollNode.addSubnode(buttonNode)
                        self.buttonNodes.append(buttonNode)
                    }
                    buttonIndex += 1
                    if buttonNode.button != button {
                        buttonNode.button = button
                        buttonNode.setTitle(button.title, with: Font.regular(16.0), with: interfaceState.theme.chat.inputButtonPanel.buttonTextColor, for: [])
                    }
                    buttonNode.frame = CGRect(origin: CGPoint(x: sideInset + CGFloat(columnIndex) * (buttonWidth + columnSpacing), y: verticalOffset), size: CGSize(width: buttonWidth, height: buttonHeight))
                    columnIndex += 1
                }
                verticalOffset += buttonHeight + rowSpacing
            }
            
            for i in (buttonIndex ..< self.buttonNodes.count).reversed() {
                self.buttonNodes[i].removeFromSupernode()
                self.buttonNodes.remove(at: i)
            }
            
            if markup.flags.contains(.fit) {
                panelHeight = min(panelHeight, rowsHeight + bottomInset)
            }
            
            transition.updateFrame(node: self.scrollNode, frame: CGRect(origin: CGPoint(), size: CGSize(width: width, height: panelHeight)))
            self.scrollNode.view.contentSize = CGSize(width: width, height: rowsHeight)
            
            return panelHeight
        } else {
            return 0.0
        }
    }
    
    @objc func buttonPressed(_ button: ASButtonNode) {
        if let button = button as? ChatButtonKeyboardInputButtonNode, let markupButton = button.button {
            switch markupButton.action {
                case .text:
                    controllerInteraction.sendMessage(markupButton.title)
                case let .url(url):
                    controllerInteraction.openUrl(url)
                case .requestMap:
                    controllerInteraction.shareCurrentLocation()
                case .requestPhone:
                    controllerInteraction.shareAccountContact()
                case .openWebApp:
                    if let message = self.message {
                        controllerInteraction.requestMessageActionCallback(message.id, nil, true)
                    }
                case let .callback(data):
                    if let message = self.message {
                        controllerInteraction.requestMessageActionCallback(message.id, data, false)
                    }
                case let .switchInline(samePeer, query):
                    if let message = message {
                        var botPeer: Peer?
                        
                        var found = false
                        for attribute in message.attributes {
                            if let attribute = attribute as? InlineBotMessageAttribute {
                                botPeer = message.peers[attribute.peerId]
                                found = true
                            }
                        }
                        if !found {
                            botPeer = message.author
                        }
                        
                        var peerId: PeerId?
                        if samePeer {
                            peerId = message.id.peerId
                        }
                        if let botPeer = botPeer, let addressName = botPeer.addressName {
                            controllerInteraction.openPeer(peerId, .chat(textInputState: ChatTextInputState(inputText: NSAttributedString(string: "@\(addressName) \(query)")), messageId: nil), nil)
                        }
                    }
                case .payment:
                    break
            }
        }
    }
}
